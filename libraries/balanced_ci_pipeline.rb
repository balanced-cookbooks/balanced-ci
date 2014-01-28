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

class Chef
  class Resource::BalancedCiPipeline < Resource
    include Poise(parent: CiServer, parent_optional: true)
    actions(:enable)
    attr_reader :jobs

    attribute(:python_package, kind_of: String, default: lazy { name })
    attribute(:omnibus_package, kind_of: String, default: lazy { name })
    attribute(:repository, kind_of: String, default: lazy { node['ci']['repository'] }, required: true)
    attribute(:omnibus_repository, kind_of: String, default: lazy { node['balanced-ci']['omnibus_repository'] })
    attribute(:cookbook_repository, kind_of: String, required: true)
    attribute(:pipeline, kind_of: Array, default: %w{test quality build acceptance deploy_staging deploy_test})

    attribute(:test_db_user, kind_of: String)
    attribute(:test_db_name, kind_of: String,)
    attribute(:test_db_host, kind_of: String, default: 'localhost')

    attribute(:test_command, kind_of: String, default: 'python setup.py test')
    attribute(:quality_command, kind_of: String, default: 'echo 1')
    attribute(:build_command, kind_of: String) # Default is in template
    attribute(:acceptance_command, kind_of: String) # Default is in template
    attribute(:deploy_test_command, kind_of: String, default: 'echo 1')
    attribute(:deploy_staging_command, kind_of: String, default: 'echo 1')
    attribute(:source, kind_of: String, default: 'job.xml.erb')

    attribute(:project_url, kind_of: String)
    attribute(:branch, kind_of: String, default: 'master')

    attribute(:project_prefix, kind_of: String, default: '')

    attribute(:test_template, template: true, default_source: 'commands/test.sh.erb', default_options: lazy { default_command_options })
    attribute(:build_template, template: true, default_source: 'commands/build.sh.erb', default_options: lazy { default_command_options })
    attribute(:quality_template, template: true, default_source: 'commands/quality.sh.erb', default_options: lazy { default_command_options })
    attribute(:deploy_test_template, template: true, default_source: 'commands/deploy-test.sh.erb', default_options: lazy { default_command_options })
    attribute(:deploy_staging_template, template: true, default_source: 'commands/deploy-staging.sh.erb', default_options: lazy { default_command_options })
    attribute(:acceptance_template, template: true, default_source: 'commands/acceptance.sh.erb', default_options: lazy { default_command_options })
    attribute(:env_template, template: true, default_source: 'commands/env.sh.erb', default_options: lazy { default_command_options })

    def initialize(*args)
      super
      @jobs = {}
    end

    def job(name, &block)
      (@jobs[name] ||= []) << block
    end

    def default_command_options
      {
        aws: {
          access_key_id: citadel.access_key_id,
          secret_access_key: citadel.secret_access_key,
          token: citadel.token,
        },
        aws_travis: {
          access_key_id: citadel['travis/aws_access_key_id'],
          secret_access_key: citadel['travis/aws_secret_access_key'],
        },
      }
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

    def self.default_job(name, &block)
      @default_jobs ||= {}
      @default_jobs[name] = block if block
      @default_jobs[name]
    end

    private

    def create_job(name)
      raise "Unknown job #{name}" unless self.class.default_job(name) || (new_resource.jobs[name] && !new_resource.jobs[name].empty?)
      job = balanced_ci_job "#{new_resource.name}-#{name}" do
        parent new_resource.parent
        repository new_resource.repository
        branch new_resource.branch
        source new_resource.source
        server_api_key citadel['jenkins_builder/hashedToken']
        builder_label new_resource.name
      end
      job.instance_exec(new_resource, &self.class.default_job(name)) if self.class.default_job(name)
      if new_resource.jobs[name]
        new_resource.jobs[name].each do |block|
          job.instance_exec(new_resource, &block)
        end
      end
      job
    end

    # Run unit tests
    default_job 'test' do |new_resource|
      # For solo (dev mode) don't poll
      scm_trigger Chef::Config[:solo] ? '' : '* * * * *'
      command new_resource.test_template_content
      clone_workspace true
      parameterized false
      junit '**/nosetests.xml'
      downstream_triggers ["#{new_resource.name}-quality"]
      environment_script new_resource.env_template_content
      builder_recipe do
        include_recipe 'git'
        include_recipe 'python'
        include_recipe 'balanced-python'
        # include_recipe 'balanced-rabbitmq'
        # include_recipe 'balanced-elasticsearch'
        # include_recipe 'balanced-postgres'
        # include_recipe 'balanced-mongodb'

        # package 'libxml2-dev'
        # package 'libxslt1-dev'

        # include_recipe 'postgresql::client'
        # include_recipe 'postgresql::ruby'

        # postgresql_database_user new_resource.test_db_user do
        #   connection host: new_resource.test_db_host
        #   password ''
        # end

        # postgresql_database new_resource.test_db_name do
        #   connection host: new_resource.test_db_host
        # end

        # # YOLO and I don't care right now
        # execute "psql -c 'alter user #{new_resource.test_db_user} with superuser'" do
        #   user 'postgres'
        # end
      end
    end

    # Run linters and other code quality checks
    default_job 'quality' do |new_resource|
      inherit "#{new_resource.name}-test"
      command new_resource.quality_template_content
      cobertura '**/coverage.xml'
      violations true
      conditional_continue job_name: "#{new_resource.name}-build"

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
    default_job 'build' do |new_resource|
      repository new_resource.omnibus_repository
      branch 'master'
      command new_resource.build_template_content
      parameterized true
      downstream_triggers ["#{new_resource.name}-acceptance"]

      builder_recipe do
        include_recipe 'balanced-omnibus'
        include_recipe 'python'
        python_pip 'depot' do
          action :upgrade
          user 'root'
        end
        sudo 'jenkins' do
          user 'jenkins'
          nopasswd true
        end
        file '/root/packages@vandelay.io.pem' do
          owner 'root'
          group 'root'
          mode '600'
          content citadel['jenkins_builder/packages@vandelay.io.pem']
        end
        execute 'gpg --import /root/packages@vandelay.io.pem' do
          user 'root'
          not_if 'env HOME=/root gpg --list-secret-keys 277E7787'
          environment 'HOME' => Dir.home('root') # Because GPG uses $HOME instead of real home
        end
      end
    end

    # Run acceptance tests
    default_job 'acceptance' do |new_resource|
      repository new_resource.cookbook_repository
      branch 'master'
      parameterized true
      command new_resource.acceptance_template_content
      builder_recipe do
        include_recipe 'poise-ruby::ruby-210'
        gem_package 'bundler' do
          gem_binary '/opt/ruby-210/bin/gem'
        end
        file '/srv/ci/travis.pem' do
          owner 'root'
          group 'root'
          mode '644'
          content citadel['travis/us-east-1.pem']
        end
        file '/srv/ci/travis_client.pem' do
          owner 'root'
          group 'root'
          mode '644'
          content citadel['travis/client.pem']
        end
        file '/srv/ci/berkshelf.json' do
          owner 'root'
          group 'root'
          mode '644'
          content({
            chef: {
              chef_server_url: Chef::Config[:solo] ? 'https://confucius.balancedpayments.com/' : Chef::Config[:chef_server_url],
              node_name: 'travis',
              client_key: '/srv/ci/travis_client.pem',
            },
          }.to_json)
        end
      end
    end

    # Deploy to staging environment
    default_job 'deploy_staging' do |new_resource|
      inherit "#{new_resource.name}-test"
      parameterized true
      command new_resource.deploy_staging_template_content
      downstream_triggers ["acceptance"]
      downstream_joins ["#{new_resource.name}-deploy_test"]
    end

    # Deploy to test environment (which is not where tests are run, FYI)
    default_job 'deploy_test' do |new_resource|
      inherit "#{new_resource.name}-test"
      parameterized true
      command new_resource.deploy_test_template_content
    end

  end
end
