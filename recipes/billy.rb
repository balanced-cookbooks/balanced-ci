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
  pipeline %w{test quality build}
  project_url 'https://github.com/balanced/billy'
  branch 'master'
  test_db_user 'billy'
  test_db_name 'billy_test'
  test_db_host 'localhost'
  test_command <<-COMMAND
export BILLY_TEST_ALEMBIC=1 
export BILLY_UNIT_TEST_DB=postgresql://billy:@127.0.0.1/billy_test 
export BILLY_FUNC_TEST_DB=postgresql://billy:@127.0.0.1/billy_test
pip install psycopg2
nosetests -v -s --with-id --with-xunit --cover-package=billy --cover-erase
COMMAND
  quality_command 'coverage.py coverage.xml billy:95'
end

include_recipe 'balanced-ci'
# TODO: okay... seems postgresql is not installed, maybe we should 
# include the recipe here?
