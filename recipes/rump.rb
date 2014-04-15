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
  cookbook_repository 'git@github.com:balanced-cookbooks/role-balanced-proxy.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/rump'
  branch 'master'
  project_prefix 'src/'
  test_command <<-COMMAND.gsub(/^ {4}/, '')
    pip install nose==1.3.0
    pip install mock==0.8
    pip install unittest2
    cd src
    nosetests -v -s --with-id --with-xunit --with-xcoverage --cover-package=rump --cover-erase
  COMMAND
  quality_command 'coverage.py src/coverage.xml rump:50 rump.parser:50 rump.request:50'

end

include_recipe 'balanced-ci'
