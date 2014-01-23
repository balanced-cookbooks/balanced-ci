# balanced-ci

Configure all aspects of the Balanced CI environment and pipeline system.

## Development

1. `bundle install`.
1. `vagrant up server`. This may periodically fail so then run `vagrant provision server`.
1. `vagrant up builder`. This should only be done after the server is provisioned.

UI lives at http://10.2.3.4:8080/ once it's running.

## Deploying a new builder

In the confucius repository, create a new role for your pipeline. See the existing
`jenkins-builder-*` roles for an example. Then launch a new instance using the
same settings as on of the existing ones (TODO: use troposphere for this).
