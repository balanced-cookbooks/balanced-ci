#
# Author:: Noah Kantrowitz <noah@coderanger.net>
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


balanced_ci_pipeline 'rump' do
  repository 'git@github.com:balanced/rump.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/rump'
  branch 'ohaul'
  project_prefix 'src/'
  test_command <<-COMMAND
pip install nose==1.3.0
pip install mock==0.8
pip install unittest2
cd src
nosetests -v -s --with-id --with-xunit --with-xcoverage --cover-package=rump --cover-erase
COMMAND
  quality_command 'coverage.py src/coverage.xml rump:50 rump.parser:50 rump.request:50'

  cookbook_repository 'git@github.com:balanced-cookbooks/role-balanced-proxy.git'

  # configure the pipeline job name to have a conditional success
  job 'test' do |new_resource|
    conditional_continue {
      :job_name => 'quality'
    }
  end

  # Run acceptance tests
  job 'acceptance' do |new_resource|
    repository new_resource.cookbook_repository
    # TODO: this doesn't work so moved into mvp_builder recipe
    #builder_recipe do
    #  include_recipe 'poise-ruby::ruby-210'
    #  gem_package 'bundler' do
    #    gem_binary '/opt/ruby-210/bin/gem'
    #  end
    #end
  end
  acceptance_command <<-COMMAND
  export PATH="/opt/ruby-210/bin:$PATH"
  bundle install --binstubs --path=.
  env KITCHEN_LOCAL_YAML=.kitchen.jenkins.yml bin/kitchen test -d always
  COMMAND

end

include_recipe 'balanced-ci'
