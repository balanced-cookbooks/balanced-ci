name 'balanced-ci'
version '0.0.1'

depends 'ci', '~> 0.0.1'
depends 'balanced-citadel', '~> 0.0.1'

# For build slaves
depends 'database'
depends 'python'
depends 'balanced-rabbitmq'
depends 'balanced-elasticsearch'
depends 'balanced-postgres'
depends 'balanced-mongodb'
