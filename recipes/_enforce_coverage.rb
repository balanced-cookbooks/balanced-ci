#
# Author:: Balanced <dev@balancedpayments.com>
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

ci_job "#{node[:unit_tests][:job_name]}-enforce-coverage" do
  source 'job-acceptance.xml.erb'
  server_api_key citadel['jenkins_builder/hashedToken']

  builder_recipe do
    include_recipe 'git'
    include_recipe 'python'

  end

  downstream_joins node[:acceptance][:downstream_joins]
  downstream_triggers node[:acceptance][:downstream_triggers]

  command <<-'COMMAND'
echo Build is: ${PP_BUILD}

PYENV_HOME=~/.jenkins_pyenv

# Consistent environments are more consistent
source /etc/profile

# Create virtualenv and install necessary packages
/usr/local/bin/virtualenv $PYENV_HOME
. $PYENV_HOME/bin/activate
pip install lxml

COVERAGE_ARGS="#{node[:unit_tests][:package_name]}.models:91 #{node[:unit_tests][:package_name]}.resources:92 --strict"

COVERAGE_FILE=coverage.xml

~/coverage.py $COVERAGE_FILE $COVERAGE_ARGS
  COMMAND
end

include_recipe 'balanced-ci'
