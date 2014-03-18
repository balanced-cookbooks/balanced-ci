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

balanced_ci_pipeline 'injustice' do
  repository 'git@github.com:balanced/injustice.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/role-balanced-dashboard-auth.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/injustice'
  branch 'master'
  test_command <<-COMMAND.gsub(/^ {4}/, '')
    pip install mock==0.8
    pip install unittest2
    pip install jsonschema==1.1.0
    ./manage.py test --with-id --with-xunit --with-xcoverage --cover-package=injustice --cover-erase
  COMMAND
  quality_command 'coverage.py coverage.xml injustice_service.apps:80 injustice_service.lib:80'
end

include_recipe 'balanced-ci'
