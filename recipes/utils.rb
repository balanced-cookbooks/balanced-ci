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

# this job promotes unstable apt package in apt.vandelay.io to stable
ci_job 'utils-promote' do

  repository nil
  source 'promote_job.xml.erb'
  server_api_key citadel['jenkins_builder/hashedToken']
  command <<-COMMAND
echo "Promoting package ${PACKAGE} @ ${VERSION} ..."

# ensure the virtualenv is created
if [ ! -d ".pyenv" ]; then
  virtualenv .pyenv
fi
# activate the environment
source .pyenv/bin/activate

pip install --upgrade depot==0.0.12

# run depot as root (need to get the key for signing package)
export DEPOT_BIN=`which depot`
export TARGET_URL="s3://apt.vandelay.io/pool/${PACKAGE}_${VERSION}_amd64.deb"
# ------------------------------------------------------------------------------
sudo bash -xe <<DEPOT

# expose AWS keys
set +x # Redact credentials from log
echo Setting AWS credentials
export AWS_ACCESS_KEY_ID="#{ citadel['depot/aws_access_key_id'].strip }"
export AWS_SECRET_ACCESS_KEY="#{ citadel['depot/aws_secret_access_key'].strip }"
set -x

# submit package
export HOME=/root
$DEPOT_BIN -s s3://apt.vandelay.io -k 277E7787 -c precise --component main --no-public --force $TARGET_URL

DEPOT
# ------------------------------------------------------------------------

COMMAND

  builder_recipe do
    include_recipe 'python'
    python_pip 'virtualenvwrapper' do
        action :install
        version '4.2'
    end
    package 'libxml2-dev'
    package 'libxslt1-dev'
    # add jenkins to sudoers so that it can access packages@vandelay.io.pem
    sudo 'jenkins' do
      user 'jenkins'
      nopasswd true
    end
    file '/root/packages@vandelay.io.pem' do
      owner 'root'
      group 'root'
      mode '600'
      content citadel['jenkins_builder/packages@vandelay.io.pem']
    end
    execute 'gpg --import /root/packages@vandelay.io.pem' do
      user 'root'
      not_if 'env HOME=/root gpg --list-secret-keys 277E7787'
      environment 'HOME' => Dir.home('root') # Because GPG uses $HOME instead of real home
    end
  end

end

include_recipe 'balanced-ci'
