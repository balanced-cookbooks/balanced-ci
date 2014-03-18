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

name 'balanced-ci'
version '1.0.94'

maintainer 'Noah Kantrowitz'
maintainer_email 'noah@coderanger.net'
license 'Apache 2.0'
description 'Installs and configures Balanced CI server and jobs'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

# No way to apply two constraints in either Chef or Berkshelf that I can find :-(
depends 'poise', '~> 1.0'#, '>= 1.0.10'
depends 'ci', '~> 1.0'#, '>= 1.0.20'
depends 'balanced-citadel'
depends 'postfix', '>= 3.0.4'
depends 'nginx'
depends 'sudo'

# For build slaves
depends 'balanced-elasticsearch'
depends 'balanced-mongodb'
depends 'balanced-omnibus', '~> 1.0.2'
depends 'balanced-postgres'
depends 'balanced-rabbitmq'
depends 'database'
depends 'poise-ruby'
depends 'postgresql'
depends 'python'
depends 'redisio'
depends 'newrelic-sysmond'
