
class Chef

  class Resource::BalancedCiJob < Resource::CiJob
    attribute(:downstream_triggers, kind_of: Array, default: [])
    attribute(:downstream_joins, kind_of: Array, default: [])

    attribute(:project_url, kind_of: String, default: nil)
    attribute(:branch, kind_of: String, default: nil)
    attribute(:cobertura, kind_of: String, default: nil)
    attribute(:mailer, kind_of: String, default: nil)
    attribute(:junit, kind_of: Hash, default: {})
    attribute(:violations, kind_of: Hash, default: {})
    attribute(:clone_workspace, kind_of: Hash, default: {})

  end

  class Provider::BalancedCiJob < Provider::CiJob

    private

    def create_job
      jenkins_job new_resource.job_name do
        source new_resource.source
        cookbook new_resource.cookbook
        content new_resource.content
        parent new_resource.parent

        project_url new_resource.project_url
        repository new_resource.repository
        branch new_resource.branch
        cobertura new_resource.cobertura
        mailer new_resource.mailer
        junit new_resource.junit
        violations = new_resource.violations
        clone_workspace = new_resource.clone_workspace

        options do
          repository new_resource.repository
          command REXML::Text.normalize(new_resource.command)
          builder_label new_resource.builder_label if new_resource.builder_label
          downstream_triggers new_resource.downstream_triggers
          downstream_joins new_resource.downstream_joins
        end
      end
    end

    #def default_options
    #  super.merge(
    #    {
    #      :project_url: attribute(kind_of: String, default: nil)
    #    }
    #  )
    #end
    #
  end

end

