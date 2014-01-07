##
## Copyright 2013, Balanced, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#
#
#node.override[:unit_tests][:job_name] = 'balanced'
#node.override[:unit_tests][:repository] = 'git@github.com:PoundPay/balanced.git'
#node.override[:unit_tests][:db_user] = 'balanced_test'
#node.override[:unit_tests][:db_name] = 'balanced_test'
#node.override[:unit_tests][:package_name] = 'balanced_service'
#node.override[:unit_tests][:downstream_joins] = {
#    'balanced-deploy-staging' => 'SUCCESS'
#}
#node.override[:unit_tests][:downstream_triggers] = {
#    'balanced-enforce-coverage' => 'SUCCESS'
#}
#
#node.override[:staging_deploy][:job_name] = 'balanced'
#node.override[:staging_deploy][:db_user] = 'balanced_staging'
#node.override[:staging_deploy][:db_name] = 'balanced_staging'
#node.override[:staging_deploy][:downstream_joins] = {
#    'balanced-deploy-test' => 'SUCCESS'
#}
#node.override[:staging_deploy][:downstream_triggers] = {
#    'acceptance' => 'SUCCESS'
#}
#
#node.override[:acceptance][:job_name] = 'acceptance'
#node.override[:acceptance][:downstream_joins] = {}
#node.override[:acceptance][:downstream_triggers] = {}
#
#node.override[:test_deploy][:job_name] = 'balanced'
#node.override[:test_deploy][:downstream_joins] = {}
#node.override[:test_deploy][:downstream_triggers] = {}
#
#include_recipe 'balanced-ci::_run_unit_tests'
#include_recipe 'balanced-ci::_enforce_coverage'
#include_recipe 'balanced-ci::_deploy_to_staging'
#include_recipe 'balanced-ci::_acceptance'
#include_recipe 'balanced-ci::_deploy_to_test'
node.override['ci']['repository'] = 'git@github.com:PoundPay/balanced.git'
balanced_ci_pipeline 'balanced' do
  package_name 'balanced_service'
  test_db_user 'balanced'
  test_db_name 'balanced_test'
  test_db_host 'localhost'
end
