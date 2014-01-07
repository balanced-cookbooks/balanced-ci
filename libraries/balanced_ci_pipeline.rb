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

class Chef
  class Resource::BalancedCiPipeline < Resource
    include Poise(parent: CiServer, parent_optional: true)
    actions(:enable)

    attribute(:package_name, kind_of: String, required: true)
    attribute(:repository, kind_of: String, default: lazy { node['ci']['repository'] }, required: true)

    attribute(:test_db_user, kind_of: String, required: true)
    attribute(:test_db_name, kind_of: String, required: true)
    attribute(:test_db_host, kind_of: String, default: 'localhost', required: true)
  end

  class Provider::BalancedCiPipeline < Provider
    include Poise

    def action_enable
      converge_by("create CI pipeline for #{new_resource.name}") do
        notifying_block do
          create_test_job
          create_enforce_coverage_job
          create_build_job
          create_staging_deploy_job
          create_test_deploy_job
        end
      end
    end

    private

    def create_test_job
      ci_job "#{new_resource.name}-test" do
        parent new_resource.parent
        repository new_resource.repository
        downstream_triggers ["#{new_resource.name}-enforce-coverage"]
        downstream_joins ["#{new_resource.name}-build"]
        builder_label 'master'  # ?

        source 'job-balanced.xml.erb'

        builder_recipe do
          include_recipe 'git'
          include_recipe 'python'
          include_recipe 'python-balanced'
          include_recipe 'balanced-rabbitmq'
          include_recipe 'balanced-elasticsearch'
          include_recipe 'balanced-postgres'
          include_recipe 'balanced-mongodb'

          package 'libxml2-dev'
          package 'libxslt1-dev'

          include_recipe 'postgresql::client'
          include_recipe 'postgresql::ruby'

          postgresql_database_user new_resource.test_db_name do
            connection host: new_resource.test_db_host
            password ''
          end

          postgresql_database new_resource.test_db_name do
            connection host: new_resource.test_db_host
          end

          # YOLO and I don't care right now
          execute "psql -c 'alter user #{new_resource.test_db_user} with superuser'" do
            user 'postgres'
          end
        end

        command <<-COMMAND.gsub!(/^ {10}/, '')
          echo Build is: ${PP_BUILD}

          PYENV_HOME=$WORKSPACE/.pyenv/

          # Consistent environments are more consistent
          source /etc/profile

          virtualenv $PYENV_HOME
          . $PYENV_HOME/bin/activate

        COMMAND
      end
    end # /create_test_job

    def create_build_job
      ci_job "#{new_resource.name}-build" do
        parent new_resource.parent

        downstream_triggers ["#{new_resource.name}-deploy-staging"]
        downstream_joins []
        builder_label 'master'  # ?

        source 'job-balanced.xml.erb'

        builder_recipe do
          include_recipe 'git'
          include_recipe 'python'
        end

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

    def create_enforce_coverage_job
      ci_job "#{new_resource.name}-enforce-coverage" do
        parent new_resource.parent

        downstream_triggers []
        downstream_joins []
        builder_label 'master'  # ?

        source 'job-balanced.xml.erb'

        builder_recipe do
          include_recipe 'git'
          include_recipe 'python'
        end

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

    def create_staging_deploy_job
      ci_job "#{new_resource.name}-deploy-staging" do
        parent new_resource.parent
        repository new_resource.repository
        builder_label 'master'  # ?

        downstream_triggers ["acceptance"]
        downstream_joins ["#{new_resource.name}-deploy-test"]

        builder_recipe do
          include_recipe 'git'
          include_recipe 'python'
        end

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

    def create_test_deploy_job
      ci_job "#{new_resource.name}-deploy-test" do
        parent new_resource.parent
        repository new_resource.repository
        builder_label 'master'  # ?

        downstream_triggers []
        downstream_joins []

        builder_recipe do
          include_recipe 'git'
          include_recipe 'python'
        end

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