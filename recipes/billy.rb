#
# Author:: Victor Lin <victorlin@balancedpayments.com>
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


balanced_ci_pipeline 'billy' do
  repository 'git@github.com:balanced/billy.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/role-balanced-billy.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/billy'
  branch 'master'
  test_db_user 'billy'
  test_db_name 'billy_test'
  test_db_host 'localhost'
  test_command <<-COMMAND
export BILLY_TEST_ALEMBIC=1
export BILLY_UNIT_TEST_DB=postgresql://billy:billy@localhost/billy_test
export BILLY_FUNC_TEST_DB=postgresql://billy:billy@localhost/billy_test
pip install --no-use-wheel psycopg2
pip install --no-use-wheel nosexcover
nosetests -v -s --with-id --with-xunit --with-xcoverage --cover-package=billy --cover-erase
COMMAND
  quality_command 'blumpkin coverage coverage.xml billy:95'

  job 'build' do |new_resource|
    promotion true
  end

  job 'test' do |new_resource|
    builder_recipe do
      include_recipe 'git'
      include_recipe 'python'
      include_recipe 'balanced-ci'
      include_recipe 'balanced-postgresql'
      include_recipe 'balanced-postgresql::server'
      include_recipe 'balanced-postgresql::client'

      pg_user new_resource.test_db_user do
        privileges superuser: true, createdb: true, login: true
        password 'billy'
      end

      pg_database new_resource.test_db_name do
        owner new_resource.test_db_user
      end

      execute "psql -c 'alter user #{new_resource.test_db_user} with superuser'" do
        user 'postgres'
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
end

include_recipe 'balanced-ci'
