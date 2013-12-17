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
    include_recipe 'git'
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

  command <<-COMMAND
PYENV_HOME=$WORKSPACE/.pyenv/

# Consistent environments are more consistent
source /etc/profile
PATH=$PATH:/usr/local/bin

# Delete previously built virtualenv if requirements have changed
REBUILD_VIRTUALENV=0
REQ_FILES=&quot;requirements.txt deploy-requirements.txt test-requirements.txt requirements-deploy.txt requirements-test.txt&quot;

for req in $REQ_FILES setup.py; do    # Don't execute setup.py, but track it
  LAST_REQUIREMENTS=&quot;$WORKSPACE/../$req&quot;
  REQS=&quot;$WORKSPACE/$req&quot;
  if [ -e $REQS ]; then
     if [ ! -e $LAST_REQUIREMENTS ] || ! diff -aq $LAST_REQUIREMENTS $REQS; then
        REBUILD_VIRTUALENV=1
     fi
     cp $REQS $LAST_REQUIREMENTS
  fi
done
if [ -d $PYENV_HOME ] &amp;&amp; [ $REBUILD_VIRTUALENV -ne 0 ]; then
   rm -rf $PYENV_HOME
fi

# Create virtualenv and install necessary packages. This can be done even for
# non-python (Play, e.g.) projects, if they have deploy requirements.
virtualenv $PYENV_HOME
. $PYENV_HOME/bin/activate
if [ -e $WORKSPACE/setup.py ]; then
  python $WORKSPACE/setup.py develop
fi
for req in $REQ_FILES; do
  if [ -e $req ]; then
    pip install -r $req
  fi
done
pip install --quiet pylint
pip install --quiet pep8
pip install --quiet nosexcover

# Clear out stale .pyc files
find $WORKSPACE -path $PYENV_HOME -prune -o -name &quot;*.pyc&quot; -print0 | xargs -0 rm

# Rebuild test db if necessary/possible
REBUILD_DB_SCRIPTS=&quot;scripts/db-recreate-test scripts/recreate-test-db db/rebuild-db&quot;
for script in $REBUILD_DB_SCRIPTS; do
  if [ -e $script ]; then
    $script
    break
  fi
done

# Rebuild test es if necessary/possible
REBUILD_ES_SCRIPTS=&quot;scripts/recreate-test-es&quot;
for script in $REBUILD_ES_SCRIPTS; do
  if [ -e $script ]; then
    $script
    break
  fi
done

# Rebuild test msg if necessary/possible
REBUILD_MSG_SCRIPTS=&quot;scripts/recreate-test-msg&quot;
for script in $REBUILD_MSG_SCRIPTS; do
  if [ -e $script ]; then
    $script
    break
  fi
done

COMMON_ARGS="-s --with-id --with-xunit --with-xcoverage --cover-package=balanced_service --cover-erase"
if [ -e $WORKSPACE/manage.py ]; then
    $WORKSPACE/manage.py test -v2 $COMMON_ARGS || true
else
    nosetests -v $COMMON_ARGS || true
fi

# Pylint
python -c &quot;import sys, pylint.lint; pylint.lint.Run(sys.argv[1:])&quot; --output-format=parseable --include-ids=y --reports=n --disable=R0904,R0201,R0903,E1101,C0111,W0232,C0103,W0142,W0201,W0511,E1002,E1103,W0403,R0801 --generated-members= --ignore-iface-methods= --dummy-variables-rgx= balanced_service/ | tee pylint.out

# Pep8
find balanced_service -name \*.py | xargs pep8 --ignore=E711 | tee pep8.out
COMMAND
end

include_recipe 'balanced-ci'
