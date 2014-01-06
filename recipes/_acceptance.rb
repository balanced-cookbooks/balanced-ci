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

ci_job "acceptance" do
  source 'job-acceptance.xml.erb'
  server_api_key citadel['jenkins_builder/hashedToken']

  builder_recipe do
    include_recipe 'git'
    include_recipe 'python'

  end

  downstream_joins node[:acceptance][:downstream_joins]
  downstream_triggers node[:acceptance][:downstream_triggers]

  command <<-'COMMAND'
PYENV_HOME=$WORKSPACE/.pyenv/

# Consistent environments are more consistent
source /etc/profile

# HACK: this is all crap
git checkout master
git pull  # TODO: wtf? why do i have to do this?

# Delete previously built virtualenv if requirements have changed
REBUILD_VIRTUALENV=0
REQ_FILES="requirements.txt deploy-requirements.txt test-requirements.txt"

for req in $REQ_FILES; do
  LAST_REQUIREMENTS="$WORKSPACE/../$req"
  REQS="$WORKSPACE/$req"
  if [ -e $REQS ]; then
     if [ ! -e $LAST_REQUIREMENTS ] || ! diff -aq $LAST_REQUIREMENTS $REQS; then
        REBUILD_VIRTUALENV=1
     fi
     cp $REQS $LAST_REQUIREMENTS
  fi
done

if [ -d $PYENV_HOME ] && [ $REBUILD_VIRTUALENV -ne 0 ]; then
   rm -rf $PYENV_HOME
fi

# Create virtualenv and install necessary packages
/usr/local/bin/virtualenv $PYENV_HOME
. $PYENV_HOME/bin/activate

if [ -e $WORKSPACE/setup.py ]; then
  pip install --quiet $WORKSPACE/  # where your setup.py lives
fi

for req in $REQ_FILES; do
  if [ -e $req ]; then
    pip install -r $req
  fi
done

# Clear out stale .pyc files
find $WORKSPACE -path $PYENV_HOME -prune -o -name "*.pyc" -print0 | xargs -0 rm

# Turn off port forwarding
sudo /etc/init.d/iptables stop

# Run Tests
nosetests -sv --with-id --with-xunit || true

# Turn port forwarding back on
sudo /etc/init.d/iptables restart
  COMMAND
end

include_recipe 'balanced-ci'
