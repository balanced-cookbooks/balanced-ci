name 'ci-server'
run_list %w{recipe[ci::server] recipe[balanced-ci]}
