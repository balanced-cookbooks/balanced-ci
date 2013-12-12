#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Balanced, Inc.
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

ci_job 'balanced' do
  repository 'git@github.com:PoundPay/balanced.git'
  source 'job-balanced.xml.erb'
  server_api_key citadel['jenkins_builder/hashedToken']

  builder_recipe do
    include_recipe 'python'
    include_recipe 'balanced-rabbitmq'
    include_recipe 'balanced-elasticsearch'
    include_recipe 'balanced-postgres'
    include_recipe 'balanced-mongodb'

    package 'libxml2-dev'
    package 'libxslt1-dev'

    include_recipe 'postgresql::client'
    include_recipe 'postgresql::ruby'
    postgresql_database_user 'balanced' do
      connection host: 'localhost'
      password ''
    end

    postgresql_database 'balanced_test' do
      connection host: 'localhost'
    end

    # YOLO and I don't care right now
    execute "psql -c 'alter user balanced with superuser'" do
      user 'postgres'
    end
  end
end

include_recipe 'balanced-ci'
