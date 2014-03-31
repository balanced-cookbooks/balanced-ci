balanced_ci_pipeline 'brache' do

  repository 'git@github.com:balanced/brache.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/role-balanced-auth.git'
  project_url 'https://github.com/balanced/brache'
  branch 'master'

  pipeline %w{test quality build acceptance}

  job 'test' do |new_resource|
    builder_recipe do
      include_recipe 'git'
      include_recipe 'python'
      include_recipe 'postgresql::client'

      group node['jenkins']['node']['group']

      user node['jenkins']['node']['user'] do
        comment 'Jenkins CI node'
        gid node['jenkins']['node']['group']
        home node['ci']['path']
      end

      directory node['ci']['path'] do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
      end

      directory "#{node['ci']['path']}/.pip" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '700'
      end

      file "#{node['ci']['path']}/.pip/pip.conf" do
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '600'
        content "[global]\nindex-url = https://omnibus:#{citadel['omnibus/devpi_password'].strip}@pypi.vandelay.io/balanced/prod/+simple/\n"
      end
    end
  end

  test_command <<-COMMAND.gsub(/^ {4}/, '')
    pip install --no-use-wheel -e .[user,test,router]
    nosetests -v -s --with-id --with-xunit --with-xcoverage --cover-package=brache --cover-erase
  COMMAND

  quality_command 'coverage.py coverage.xml brache:50'

end

include_recipe 'balanced-ci'
