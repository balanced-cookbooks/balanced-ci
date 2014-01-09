
class Chef

  class Resource::BalancedCiJob < Resource::CiJob
    attribute(:downstream_triggers, kind_of: Array, default: [])
    attribute(:downstream_joins, kind_of: Array, default: [])

  end

  class Provider::BalancedCiJob < Provider::CiJob

    private

    def create_job
      jenkins_job new_resource.job_name do
        source new_resource.source
        cookbook new_resource.cookbook
        content new_resource.content
        parent new_resource.parent

        options do
          repository new_resource.repository
          command REXML::Text.normalize(new_resource.command)
          builder_label new_resource.builder_label if new_resource.builder_label
          downstream_triggers new_resource.downstream_triggers
          downstream_joins new_resource.downstream_joins
        end
      end
    end

  end

end

