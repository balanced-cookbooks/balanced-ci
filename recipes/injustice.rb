#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2014, Balanced, Inc.
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

balanced_ci_pipeline 'injustice' do
  repository 'git@github.com:balanced/injustice.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/role-balanced-dashboard-auth.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/injustice'
  test_db_user 'injustice'
  test_db_name 'injustice'
  test_db_host 'localhost'
  branch 'omnibussed'

  test_command <<-COMMAND.gsub(/^ {4}/, '')
    pip install mock==0.8
    pip install unittest2
    pip install jsonschema==1.1.0
    INJUSTICE_SETTINGS=default ./manage.py test --with-id --with-xunit --with-xcoverage --cover-package=injustice --cover-erase
  COMMAND


  job 'test' do |new_resource|

    builder_recipe do
      include_recipe 'git'
      include_recipe 'python'
      include_recipe 'rsyslog'
      include_recipe 'balanced-postgresql'
      include_recipe 'balanced-postgresql::server'
      include_recipe 'balanced-postgresql::client'
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

    end

  end

  quality_command 'coverage.py coverage.xml injustice_service.apps:80 injustice_service.lib:80'
end

include_recipe 'balanced-ci'
