
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

