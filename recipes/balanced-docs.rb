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

balanced_ci_pipeline 'balanced-docs' do
  repository 'git@github.com:balanced/balanced-docs.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/balanced-docs.git'
  pipeline %w{gate build acceptance}
  project_url 'https://github.com/balanced/balanced-docs'
  branch 'multi-rev'

  # The docs have no tests per se, so just make a blank task to dispach to the build job.
  # TODO: This shouldn't be needed.
  default_job 'gate' do |new_resource|
    scm_trigger Chef::Config[:solo] ? '' : '* * * * *'
    command ''
    environment_script new_resource.env_template_content
    conditional_continue job_name: "#{new_resource.name}-build"
  end
end

include_recipe 'balanced-ci'
