#
# Author:: Marshall Jones <marshall@balancedpayments.com>
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

class Chef

  class Resource::BalancedCiJob < Resource::CiJob
    attribute(:downstream_triggers, kind_of: Array, default: [])
    attribute(:downstream_joins, kind_of: Array, default: [])

    attribute(:project_url, kind_of: String, default: nil)
    attribute(:branch, kind_of: String, default: nil)
    attribute(:cobertura, kind_of: Hash, default: nil)
    attribute(:mailer, kind_of: Hash, default: nil)
    attribute(:junit, kind_of: Hash, default: {})
    attribute(:violations, kind_of: Hash, default: {})
    attribute(:clone_workspace, kind_of: Hash, default: {})

    def default_options
      super.merge(
        project_url: project_url,
        repository: repository,
        branch: branch,
        cobertura: cobertura,
        mailer: mailer,
        junit: junit,
        violations: violations,
        clone_workspace: clone_workspace,
        downstream_triggers: downstream_triggers,
        downstream_joins: downstream_joins
      )
    end

  end

  class Provider::BalancedCiJob < Provider::CiJob; end

end

