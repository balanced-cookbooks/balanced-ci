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

# We don't want to run builders on the server machine
node.override['ci']['is_builder'] = false

ci_server 'balanced-ci' do
  path '/var/lib/jenkins'
  slave_agent_port 56898
  component 'git'
  component 'google_auth' do
    domain 'balancedpayments.com'
  end
  component 'secure_slaves' do
    master_key citadel['jenkins_server/master.key']
    secrets_key citadel['jenkins_server/hudson.util.Secret']
    encrypted_api_token citadel['jenkins_server/apiToken']
  end
  component 'ssl' do
    certificate citadel['jenkins_server/ssl.pem']
    key citadel['jenkins_server/ssl.key']
  end
end

jenkins_plugin 'github'
jenkins_plugin 'join'
jenkins_plugin 'parameterized-trigger'
jenkins_plugin 'run-condition'
jenkins_plugin 'environment-script'
jenkins_plugin 'conditional-buildstep'

jenkins_plugin 'clone-workspace-scm'
jenkins_plugin 'cobertura'
jenkins_plugin 'compact-columns'
jenkins_plugin 'copyartifact'
jenkins_plugin 'cron_column'
jenkins_plugin 'email-ext'
jenkins_plugin 'extra-columns'
jenkins_plugin 'git'
jenkins_plugin 'github-api'
jenkins_plugin 'hipchat'
jenkins_plugin 'log-parser'
jenkins_plugin 'monitoring'
jenkins_plugin 'ruby'
jenkins_plugin 'saferestart'
jenkins_plugin 'throttle-concurrents'
jenkins_plugin 'token-macro'
jenkins_plugin 'violations'
jenkins_plugin 'view-job-filters'
jenkins_plugin 'ansicolor'
jenkins_plugin 'promoted-builds'

include_recipe 'balanced-ci'
include_recipe 'balanced-ci::balanced'
include_recipe 'balanced-ci::balanced-docs'
include_recipe 'balanced-ci::brache'
include_recipe 'balanced-ci::cookbooks'
include_recipe 'balanced-ci::rump'
include_recipe 'balanced-ci::billy'
include_recipe 'balanced-ci::injustice'
include_recipe 'balanced-ci::doughboy'
include_recipe 'balanced-ci::chompy'
