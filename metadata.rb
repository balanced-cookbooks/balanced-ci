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
version '1.0.18'

maintainer 'Noah Kantrowitz'
maintainer_email 'noah@coderanger.net'
license 'Apache 2.0'
description 'Installs and configures Balanced CI server and jobs'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

depends 'poise', '~> 1.0.4'
depends 'ci', '~> 1.0.14'
depends 'balanced-citadel'
depends 'postfix', '>= 3.0.4'
depends 'nginx'
depends 'sudo'

# For build slaves
depends 'python'
depends 'balanced-python'
depends 'balanced-omnibus', '~> 1.0.2'
depends 'poise-ruby'
depends 'postgresql', '>= 3.2.0'
depends 'balanced-devpi'


# Not needed for rump, skipping
# depends 'database'
# depends 'balanced-rabbitmq'
# depends 'balanced-elasticsearch'
# depends 'balanced-postgres'
# depends 'balanced-mongodb'
