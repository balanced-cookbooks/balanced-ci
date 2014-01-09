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

def mvp_builder
  include_recipe 'git'
  include_recipe 'python'
  include_recipe 'balanced-python'
end

class Chef
  class Resource::BalancedCiPipeline < Resource
    include Poise(parent: CiServer, parent_optional: true)
    actions(:enable)

    attribute(:package_name, kind_of: String, required: true)
    attribute(:repository, kind_of: String, default: lazy { node['ci']['repository'] }, required: true)

    attribute(:test_db_user, kind_of: String, required: true)
    attribute(:test_db_name, kind_of: String, required: true)
    attribute(:test_db_host, kind_of: String, default: 'localhost', required: true)

    attribute(:test_command, kind_of: String, default: 'python setup.py test', required: true)
    attribute(:deploy_test_command, kind_of: String, default: 'echo 1 || echo 1', required: true)
    attribute(:deploy_staging_command, kind_of: String, default: 'echo 1 || echo 1', required: true)
    attribute(:ensure_quality_command, kind_of: String, default: 'echo 1', required: true)
    attribute(:build_command, kind_of: String, default: 'echo 1 || echo 1', required: true)
    attribute(:source, kind_of: String, required: true, default: 'job-balanced.xml.erb')

    attribute(:project_url, kind_of: String, default: nil)
    attribute(:branch, kind_of: String, default: nil)
    attribute(:cobertura, kind_of: Hash, default: nil)
    attribute(:mailer, kind_of: Hash, default: nil)
    attribute(:junit, kind_of: Hash, default: {})
    attribute(:violations, kind_of: Hash, default: {})
    attribute(:clone_workspace, kind_of: Hash, default: {})

    attribute(:project_prefix, kind_of: String, default: '')

    attribute(:foo, template: true, default_source: 'foo.erb')

  end

  class Provider::BalancedCiPipeline < Provider
    include Poise

    def action_enable
      converge_by("create CI pipeline for #{new_resource.name}") do
        notifying_block do
          create_test_job
          create_build_quality_job
          create_build_job
          create_staging_deploy_job
          create_acceptance_job
          create_test_deploy_job
        end
      end
    end

    private

    def create_test_job
      the_resource = new_resource

      balanced_ci_job "#{new_resource.name}-test" do
        parent new_resource.parent
        builder_label 'builder'
        repository new_resource.repository
        # https://github.com/balanced-cookbooks/balanced-ci/issues/8
        source 'job-balanced.xml.erb'

        downstream_triggers ["#{new_resource.name}-enforce-quality"]
        downstream_joins ["#{new_resource.name}-build"]

        server_api_key citadel['jenkins_builder/hashedToken']

        builder_recipe do
          include_recipe 'git'
          include_recipe 'python'
          include_recipe 'balanced-python'
          include_recipe 'balanced-rabbitmq'
          include_recipe 'balanced-elasticsearch'
          include_recipe 'balanced-postgres'
          include_recipe 'balanced-mongodb'

          package 'libxml2-dev'
          package 'libxslt1-dev'

          include_recipe 'postgresql::client'
          include_recipe 'postgresql::ruby'

          postgresql_database_user the_resource.test_db_user do
            connection host: the_resource.test_db_host
            password ''
          end

          postgresql_database the_resource.test_db_name do
            connection host: the_resource.test_db_host
          end

          # YOLO and I don't care right now
          execute "psql -c 'alter user #{the_resource.test_db_user} with superuser'" do
            user 'postgres'
          end
        end

        #command new_resource.foo_content

        command <<-COMMAND.gsub!(/^ {10}/, '')
          echo Build is: ${PP_BUILD}

          PYENV_HOME=$WORKSPACE/.pyenv/

          # Consistent environments are more consistent
          source /etc/profile

          REBUILD_VIRTUALENV=0
          REQ_FILES="requirements.txt deploy-requirements.txt test-requirements.txt requirements-deploy.txt requirements-test.txt"

          for req in $REQ_FILES setup.py; do    # Don't execute setup.py, but track it
            LAST_REQUIREMENTS="$WORKSPACE/../$req"
            REQS="$WORKSPACE/#{new_resource.project_prefix}$req"
            if [ -e $REQS ]; then
               if [ ! -e $LAST_REQUIREMENTS ] || ! diff -aq $LAST_REQUIREMENTS $REQS; then
                  REBUILD_VIRTUALENV=1
               fi
               cp $REQS $LAST_REQUIREMENTS
            fi
          done

          if [ -d $PYENV_HOME ] && [ $REBUILD_VIRTUALENV -ne 0 ]; then
             rm -rf $PYENV_HOME
          fi

          virtualenv $PYENV_HOME
          . $PYENV_HOME/bin/activate

          pip install --quiet nosexcover

          for req in $REQ_FILES; do
            if [ -e $WORKSPACE/#{new_resource.project_prefix}$req ]; then
              pip install -r $WORKSPACE/#{new_resource.project_prefix}$req
            fi
          done

          if [ -e $WORKSPACE/#{new_resource.project_prefix}setup.py ]; then
            if [ -z "#{new_resource.project_prefix}" ]
            then
              python $WORKSPACE/setup.py develop
            else
              pushd $WORKSPACE/#{new_resource.project_prefix} && python setup.py develop && popd;
            fi
          fi

          find $WORKSPACE -path $PYENV_HOME -prune -o -name "*.pyc" -print0 | xargs -0 rm

          # Rebuild test db if necessary/possible
          REBUILD_SCRIPTS="scripts/recreate-test"
          for script in $REBUILD_SCRIPTS; do
            if [ -e $WORKSPACE/#{new_resource.project_prefix}$script ]; then
              $WORKSPACE/#{new_resource.project_prefix}$script
              break
            fi
          done

          #{new_resource.test_command}

        COMMAND
      end
    end # /create_test_job

    def create_build_job
      balanced_ci_job "#{new_resource.name}-build" do
        parent new_resource.parent
        builder_label 'builder'
        # https://github.com/balanced-cookbooks/balanced-ci/issues/8
        source 'job-balanced.xml.erb'

        downstream_triggers ["#{new_resource.name}-deploy-staging"]
        downstream_joins []

        builder_recipe { mvp_builder }

        command <<-COMMAND.gsub!(/^ {10}/, '')
          echo Build is: ${PP_BUILD}

          PYENV_HOME=$WORKSPACE/.pyenv/

          # Consistent environments are more consistent
          source /etc/profile

          virtualenv $PYENV_HOME
          . $PYENV_HOME/bin/activate

          pip install bfab

          #{new_resource.build_command}

        COMMAND
      end
    end

    def create_build_quality_job
      balanced_ci_job "#{new_resource.name}-enforce-quality" do
        parent new_resource.parent
        builder_label 'builder'
        # https://github.com/balanced-cookbooks/balanced-ci/issues/8
        source 'job-balanced.xml.erb'

        downstream_triggers []
        downstream_joins []

        builder_recipe { mvp_builder }

        command <<-COMMAND.gsub!(/^ {10}/, '')
          echo Build is: ${PP_BUILD}

          PYENV_HOME=$WORKSPACE/.pyenv/

          # Consistent environments are more consistent
          source /etc/profile

          virtualenv $PYENV_HOME
          . $PYENV_HOME/bin/activate

          pip install coverage pep8 pylint

          # Pylint
          python -c "import sys, pylint.lint; pylint.lint.Run(sys.argv[1:])" --output-format=parseable --include-ids=y --reports=n --disable=R0904,R0201,R0903,E1101,C0111,W0232,C0103,W0142,W0201,W0511,E1002,E1103,W0403,R0801 --generated-members= --ignore-iface-methods= --dummy-variables-rgx= #{new_resource.package_name}/ | tee pylint.out

          # Pep8
          find #{new_resource.package_name} -name \*.py | xargs pep8 --ignore=E711 | tee pep8.out

          #{new_resource.ensure_quality_command}

        COMMAND
      end
    end

    def create_staging_deploy_job
      balanced_ci_job "#{new_resource.name}-deploy-staging" do
        parent new_resource.parent
        builder_label 'builder'
        repository new_resource.repository
        # https://github.com/balanced-cookbooks/balanced-ci/issues/8
        source 'job-balanced.xml.erb'

        downstream_triggers ["acceptance"]
        downstream_joins ["#{new_resource.name}-deploy-test"]

        builder_recipe { mvp_builder }

        command <<-COMMAND.gsub!(/^ {10}/, '')
          echo Build is: ${PP_BUILD}

          PYENV_HOME=$WORKSPACE/.pyenv/

          # Consistent environments are more consistent
          source /etc/profile

          virtualenv $PYENV_HOME
          . $PYENV_HOME/bin/activate

          pip install bfab

          #{new_resource.deploy_staging_command}

        COMMAND
      end
    end

    def create_test_deploy_job
      balanced_ci_job "#{new_resource.name}-deploy-test" do
        parent new_resource.parent
        builder_label 'builder'
        repository new_resource.repository
        # https://github.com/balanced-cookbooks/balanced-ci/issues/8
        source 'job-balanced.xml.erb'

        builder_recipe { mvp_builder }

        command <<-COMMAND.gsub!(/^ {10}/, '')
          echo Build is: ${PP_BUILD}

          PYENV_HOME=$WORKSPACE/.pyenv/

          # Consistent environments are more consistent
          source /etc/profile

          virtualenv $PYENV_HOME
          . $PYENV_HOME/bin/activate

          pip install bfab

          #{new_resource.deploy_test_command}

        COMMAND
      end
    end

    def create_acceptance_job
      balanced_ci_job "acceptance" do
        parent new_resource.parent
        builder_label 'builder'
        repository new_resource.repository
        # https://github.com/balanced-cookbooks/balanced-ci/issues/8
        source 'job-balanced.xml.erb'

        builder_recipe { mvp_builder }

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
