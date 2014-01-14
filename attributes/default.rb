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

default['balanced-ci']['omnibus_repository'] = 'https://github.com/balanced/omnibus-balanced.git'

# Overrides for ci templates
override['ci']['repository'] = 'https://github.com/balanced/%{name}.git'
override['ci']['builder_recipe'] = 'balanced-ci::%{name}'
default['ci']['server_url'] = 'https://ci.vandelay.io/'
default['ci']['server_hostname'] = 'ci.vandelay.io'

# Jenkins server settings
override['jenkins']['server']['install_method'] = 'war'
override['jenkins']['server']['group'] = node['jenkins']['server']['user']
override['jenkins']['server']['home_dir_group'] = node['jenkins']['server']['user']
override['jenkins']['server']['plugins_dir_group'] = node['jenkins']['server']['user']
override['jenkins']['server']['log_dir_group'] = node['jenkins']['server']['user']
override['jenkins']['server']['ssh_dir_group'] = node['jenkins']['server']['user']

# Node settings
override['jenkins']['node']['user'] = 'jenkins'
override['jenkins']['node']['group'] = 'jenkins'
override['jenkins']['node']['home'] = '/var/lib/jenkins'

# I don't even
override['postgresql']['enable_pgdg_apt'] = true

