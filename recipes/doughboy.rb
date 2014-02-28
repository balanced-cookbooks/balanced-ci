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


balanced_ci_pipeline 'doughboy' do
  repository 'git@github.com:balanced/doughboy.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/role-doughboy.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/doughboy'
  branch 'master'
  test_command <<-COMMAND
nosetests -sv --with-id --with-xunit --with-xcoverage --cover-package=doughboy --cover-erase
COMMAND

  job 'build' do |new_resource|
    promotion true
  end
end

include_recipe 'balanced-ci'
