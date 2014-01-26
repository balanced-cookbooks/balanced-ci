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
  repository 'git@github.com:PoundPay/balanced.git'
  pipeline %w{test quality build}
  project_url 'https://github.com/PoundPay/balanced'
  python_package 'balanced_service'
  test_db_user 'balanced'
  test_db_name 'balanced_test'
  test_db_host 'localhost'

  job 'build' do
    downstream_triggers [] # No acceptance for now
  end
end

include_recipe 'balanced-ci'
