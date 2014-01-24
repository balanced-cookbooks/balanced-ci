balanced_ci_pipeline 'brache' do

  repository 'git@github.com:balanced/brache.git'
  cookbook_repository 'git@github.com:balanced-cookbooks/role-balanced-auth.git'
  pipeline %w{test quality build acceptance}
  project_url 'https://github.com/balanced/brache'
  branch 'master'

  job 'test' do |new_resource|
    builder_recipe do
      include_recipe 'git'
      include_recipe 'python'
      include_recipe 'balanced-python'
      include_recipe 'postgresql::client'
      include_recipe 'rabbitmq::client'
      
      template '/srv/ci/.pydistutils.cfg' do
        cookbook 'balanced-devpi'
        owner 'jenkins'
        group 'jenkins'
        mode '600'
        source 'pydistutils.cfg.erb'
        variables password: 'EnkgU5nr4sdR5zwz'
      end

    end
  end

  test_command <<-COMMAND.gsub(/^ {4}/, '')  
    python setup.py develop easy_install brache[user,test,router]
    nosetests -v -s --with-id --with-xunit --with-xcoverage --cover-package=brache--cover-erase
  COMMAND
  
  quality_command 'coverage.py coverage.xml brache:50'
  
  job 'acceptance' do
    branch 'berks3'
  end

end

include_recipe 'balanced-ci'
