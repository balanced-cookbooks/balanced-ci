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
      include_recipe 'balanced-python'
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

      template "#{node['ci']['path']}/.pydistutils.cfg" do
        cookbook 'balanced-devpi'
        owner node['jenkins']['node']['user']
        group node['jenkins']['node']['group']
        mode '600'
        source 'pydistutils.cfg.erb'
        variables password: citadel['omnibus/devpi_password'].strip
      end
    end
  end

  test_command <<-COMMAND.gsub(/^ {4}/, '')
    python setup.py develop easy_install brache[user,test,router]
    nosetests -v -s --with-id --with-xunit --with-xcoverage --cover-package=brache --cover-erase
  COMMAND

  quality_command 'coverage.py coverage.xml brache:50'

end

include_recipe 'balanced-ci'
