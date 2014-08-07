#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013-2014, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

balanced_ci_pipeline 'balanced' do
  repository 'git@github.com:balanced/balanced.git'
  # this should really be called the "acceptance cookbook"
  cookbook_repository 'git@github.com:balanced-cookbooks/acceptance.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/balanced'
  python_package 'balanced_service'
  test_db_user 'balanced'
  test_db_name 'balanced'
  test_db_host 'localhost'
  branch 'omnibussed'

  test_command "pip install --no-use-wheel -e .[tests] && CONF=#{node['ci']['path']}/balanced.conf nosetests --processes=#{node['ci']['balanced']['parallelisms']} -sv --with-xunitmp --with-cov --cov=balanced_service --cov-report term-missing"
  quality_command 'coverage.py coverage.xml balanced_service.models:91 balanced_service.resources:92'

  job 'test' do |new_resource|

    builder_recipe do
      include_recipe 'git'
      include_recipe 'python'
      include_recipe 'rsyslog'
      include_recipe 'balanced-postgresql'
      include_recipe 'balanced-postgresql::server'
      include_recipe 'balanced-postgresql::client'
      include_recipe 'balanced-rabbitmq'
      include_recipe 'balanced-elasticsearch'
      include_recipe 'balanced-mongodb'
      include_recipe 'redisio::install'
      include_recipe 'redisio::enable'

      package 'libxml2-dev'
      package 'libxslt1-dev'

      pg_user new_resource.test_db_user do
        privileges superuser: true, createdb: true, login: true
        password new_resource.test_db_user
      end

      pg_database new_resource.test_db_name do
        owner new_resource.test_db_user
      end

      pg_database_extensions new_resource.test_db_name do
        extensions ['hstore']
      end

      directory node['ci']['path'] do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
      end

      directory "#{node['ci']['path']}/.pip" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '700'
      end

      file "#{node['ci']['path']}/.pip/pip.conf" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '600'
        content "[global]\nindex-url = https://omnibus:#{citadel['omnibus/devpi_password'].strip}@pypi.vandelay.io/balanced/prod/+simple/\n"
      end

      file "#{node['ci']['path']}/.pydistutils.cfg" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '600'
        content "[easy_install]\nindex_url = https://omnibus:#{citadel['omnibus/devpi_password'].strip}@pypi.vandelay.io/balanced/prod/+simple/\n"
      end

      # HACK: override the meta db for the balanced service. we need to figure
      # out a better strategy than this.
      file "#{node['ci']['path']}/balanced.conf" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '644'
        content <<-EOH
from balanced_service.settings import DATABASES

DATABASES['meta_masters'] = [
  "postgresql://balanced:#{citadel['balanced/meta_db_password']}@#{citadel['balanced/meta_db_host']}:5432/balanced_meta_test"
]
EOH
      end

      file "/etc/profile.d/balanced-test" do
        owner 'root'
        group 'root'
        mode '644'
        content <<-EOH
export BALANCED_CONF=#{node['ci']['path']}/balanced.conf
        EOH
      end

    end

  end

end

include_recipe 'balanced-ci'
