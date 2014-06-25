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
require 'base64'


balanced_ci_pipeline 'justitia' do
  repository 'git@github.com:balanced/justitia.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/role-justitia.git'
  # not omnibus any more
  omnibus_repository 'git@github.com:balanced/wrl.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/justitia'
  branch 'master'
  build_template_source 'commands/build_docker.sh.erb'

  job 'build' do |new_resource|
    #promotion true

    builder_recipe do
      include_recipe 'git'
      include_recipe 'python'
      include_recipe 'balanced-docker'
      # We need this not because we want to use omnibus, simplely because
      # it sets up github keys for us, so that we can pull repos
      include_recipe 'balanced-omnibus'

      # this allows us to upload the docker image
      file '/srv/ci/.dockercfg' do
        owner 'root'
        group 'root'
        mode '644'
        content({
          node['balanced-docker']['repo_url'] => {
            auth: Base64::encode64(
              "#{ node['balanced-docker']['password_file'] }:#{ citadel[node['balanced-docker']['password_file']].chomp }"
            ).chomp,
            email: node['balanced-docker']['email'],
          },
        }.to_json)
      end

      directory "#{node['ci']['path']}/.pip" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '700'
      end

      file "#{node['ci']['path']}/.pip/pip.conf" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '600'
        content "[global]\nindex-url = https://omnibus:#{citadel['omnibus/devpi_password'].strip}@pypi.vandelay.io/balanced/prod/+simple/\n"
      end

      file "#{node['ci']['path']}/.pydistutils.cfg" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '600'
        content "[easy_install]\nindex_url = https://omnibus:#{citadel['omnibus/devpi_password'].strip}@pypi.vandelay.io/balanced/prod/+simple/\n"
      end

    end
  end

end

include_recipe 'balanced-ci'
