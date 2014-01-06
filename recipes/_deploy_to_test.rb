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

ci_job "#{node[:test_deploy][:job_name]}-deploy-test" do
  source 'job-deploy-staging.xml.erb'
  server_api_key citadel['jenkins_builder/hashedToken']

  builder_recipe do
    include_recipe 'git'
    include_recipe 'python'
  end

  downstream_joins node[:test_deploy][:downstream_joins]
  downstream_triggers node[:test_deploy][:downstream_triggers]

  command <<-'COMMAND'
echo Build is: ${PP_BUILD}

PYENV_HOME=$WORKSPACE/.pyenv/

# Consistent environments are more consistent
source /etc/profile

# Assume that prior jobs in the build chain will have correctly set up the
# virtualenv -- we just need to activate it

/usr/local/bin/virtualenv $PYENV_HOME
. $PYENV_HOME/bin/activate

# Deploy to staging server
if [ -e scripts/fabfile.py ]; then
  FABFILE=scripts/fabfile.py
elif [ -e fabfile.py ]; then
  FABFILE=fabfile.py
else
  echo "No fabfile found -- can't deploy"
  exit 1
fi

fab -R test install_app:version=${PP_BUILD} -f $FABFILE
  COMMAND
end

include_recipe 'balanced-ci'
