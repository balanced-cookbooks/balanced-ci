#
# Author:: Noah Kantrowitz <noah@coderanger.net>
# Author:: Marshall Jones <marshall@balancedpayments.com>
#
# Copyright 2013-2014, Balanced, Inc.
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
    attr_reader :jobs

    attribute(:package_name, kind_of: String, required: true)
    attribute(:repository, kind_of: String, default: lazy { node['ci']['repository'] }, required: true)
    attribute(:pipeline, kind_of: Array, default: %w{test quality build acceptance deploy_staging deploy_test})

    attribute(:test_db_user, kind_of: String, required: true)
    attribute(:test_db_name, kind_of: String, required: true)
    attribute(:test_db_host, kind_of: String, default: 'localhost', required: true)

    attribute(:test_command, kind_of: String, default: 'python setup.py test', required: true)
    attribute(:deploy_test_command, kind_of: String, default: 'echo 1 || echo 1', required: true)
    attribute(:deploy_staging_command, kind_of: String, default: 'echo 1 || echo 1', required: true)
    attribute(:ensure_quality_command, kind_of: String, default: 'echo 1', required: true)
    attribute(:build_command, kind_of: String, default: 'echo 1 || echo 1', required: true)
    attribute(:source, kind_of: String, required: true, default: 'job.xml.erb')

    attribute(:project_url, kind_of: String, default: nil)
    attribute(:branch, kind_of: String, default: nil)
    attribute(:cobertura, kind_of: String, default: nil)
    attribute(:mailer, kind_of: String, default: nil)
    attribute(:junit, kind_of: String, default: nil)
    attribute(:violations, kind_of: String, default: nil)
    attribute(:clone_workspace, kind_of: String, default: nil)

    attribute(:project_prefix, kind_of: String, default: '')

    attribute(:test_template, template: true, default_source: 'commands/test.sh.erb')
    attribute(:build_template, template: true, default_source: 'commands/build.sh.erb')
    attribute(:quality_template, template: true, default_source: 'commands/quality.sh.erb')
    attribute(:deploy_test_template, template: true, default_source: 'commands/deploy-test.sh.erb')
    attribute(:deploy_staging_template, template: true, default_source: 'commands/deploy-staging.sh.erb')
    attribute(:acceptance_template, template: true, default_source: 'commands/acceptance.sh.erb')

    def initialize(*args)
      super
      @jobs = {}
    end

    def job(name, &block)
      (@jobs[name] ||= []) << block
    end
  end

  class Provider::BalancedCiPipeline < Provider
    include Poise

    def action_enable
      converge_by("create CI pipeline for #{new_resource.name}") do
        notifying_block do
          new_resource.pipeline.each do |name|
            create_job(name)
          end
        end
      end
    end

    private

    def self.default_job(name, &block)
      @default_jobs ||= {}
      @default_jobs[name] = block if block
      @default_jobs[name]
    end

    def create_job(name)
      job = balanced_ci_job "#{new_resource.name}-#{name}" do
        parent new_resource.parent
        repository new_resource.repository
        branch new_resource.branch
        # https://github.com/balanced-cookbooks/balanced-ci/issues/8
        source 'job.xml.erb'
        server_api_key citadel['jenkins_builder/hashedToken']
      end
      job.instance_exec(default_job(name)) if default_job(name)
      if new_resource.jobs[name]
        new_resource.jobs[name].each do |block|
          job.instance_exec(block)
        end
      end
      job
    end

    # Run unit tests
    default_job 'test' do
      command new_resource.test_template_content
      clone_workspace true
      junit '**/nosetests.xml'
      downstream_triggers ["#{new_resource.name}-quality"]
      downstream_joins ["#{new_resource.name}-build"]
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
    end

    # Run linters and other code quality checks
    default_job 'quality' do
      inherit "#{new_resource.name}-test"
      command new_resource.quality_template_content
      cobertura '**/coverage.xml'
      violations true

      builder_recipe do
        include_recipe 'git'
        include_recipe 'python'
        include_recipe 'balanced-python'
        package 'libxml2-dev'
        package 'libxslt1-dev'
        python_pip "git+https://github.com/msherry/coverage.py.git#egg=coverage.py" do
          action :install
        end
      end
    end

    # Build an omnibus package and push to unstable channel
    default_job 'build' do
      inherit "#{new_resource.name}-test"
      command new_resource.build_template_content
      # Until we know this works well, don't do any deployment
      #downstream_triggers ["#{new_resource.name}-deploy_staging"]
      builder_recipe { mvp_builder }
    end

    # Run acceptance tests
    default_job 'acceptance' do
      inherit "#{new_resource.name}-test"
      command new_resource.acceptance_template_content
      builder_recipe { mvp_builder }
    end

    # Deploy to staging environment
    default_job 'deploy_staging' do
      inherit "#{new_resource.name}-test"
      command new_resource.deploy_staging_template_content
      downstream_triggers ["acceptance"]
      downstream_joins ["#{new_resource.name}-deploy_test"]
      builder_recipe { mvp_builder }
    end

    # Deploy to test environment (which is not where tests are run, FYI)
    default_job 'deploy_test' do
      inherit "#{new_resource.name}-test"
      command new_resource.deploy_test_template_content
      builder_recipe { mvp_builder }
    end

  end
end
