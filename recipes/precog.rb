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


node.override[:unit_tests][:job_name] = 'precog'
node.override[:unit_tests][:repository] = 'git@github.com:balanced/precog.git'
node.override[:unit_tests][:db_user] = 'precog_test'
node.override[:unit_tests][:db_name] = 'precog_test'
node.override[:unit_tests][:package_name] = 'precog_service'

node.override[:staging_deploy][:job_name] = 'precog'
node.override[:staging_deploy][:db_user] = 'precog_staging'
node.override[:staging_deploy][:db_name] = 'precog_staging'

include_recipe 'balanced-ci::_run_unit_tests'
include_recipe 'balanced-ci::_deploy_to_test'
include_recipe 'balanced-ci::_acceptance'
include_recipe 'balanced-ci::_deploy_to_staging'
