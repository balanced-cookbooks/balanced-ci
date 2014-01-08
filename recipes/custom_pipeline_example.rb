
class Chef

  class Resource::CustomCiPipeline < Resource::BalancedCiPipeline

  end

  class Provider::CustomCiPipeline < Provider::BalancedCiPipeline

    def action_enable
      converge_by("create CI pipeline for #{new_resource.name}") do
        notifying_block do
          create_test_job
          create_custom_job
        end
      end
    end

    def create_custom_job
      balanced_ci_job "#{new_resource.name}-custom-job" do

        parent new_resource.parent
        repository new_resource.repository

        command <<-COMMAND.gsub!(/^ {10}/, '')
          echo Build is: ${PP_BUILD}

          PYENV_HOME=$WORKSPACE/.pyenv/

          # Consistent environments are more consistent
          source /etc/profile

          virtualenv $PYENV_HOME
          . $PYENV_HOME/bin/activate

        COMMAND

      end

    end

  end

end

node.override['ci']['repository'] = 'git@github.com:PoundPay/balanced.git'

custom_ci_pipeline 'custom' do
  package_name 'balanced_service'
  test_db_user 'balanced'
  test_db_name 'balanced_test'
  test_db_host 'localhost'
end

include_recipe 'balanced-ci'
