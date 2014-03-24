# balanced-ci

Configure all aspects of the Balanced CI environment and pipeline system.


## Development

1. `bundle install`.
1. `vagrant up server`. This may periodically fail so then run `vagrant provision server`.
1. `vagrant up builder`. This should only be done after the server is provisioned.

UI lives at http://10.2.3.4:8080/ once it's running.

### IF YOU ADD A NEW RECIPE

Modify the `Vagrantfile` to add it in the `labels` section. Here:

```ruby
      chef.json['jenkins'] = {
        server: {
          nodes: {
            'balanced-ci-berkshelf' => {
              labels: %w(cookbooks balanced rump brache billy balanced-docs),   <-- append your project name here
              path: '/srv/ci',
            }
          }
        }
```

## Deploying a new builder

In the confucius repository, create a new role for your pipeline. See the existing
`jenkins-builder-*` roles for an example. Then launch a new instance using the
same settings as on of the existing ones (TODO: use troposphere for this).

## Troubleshooting

If Jenkins is having trouble starting (``GET to http://balanced-ci-berkshelf:8080/api/json returned 500 / Net::HTTPInternalServerError``) and you're seeing ``java.lang.OutOfMemoryError: Java heap space`` in ``/var/log/syslog``, temporarilly increase the server memory to 2048 in the following section of ``Vagrantfile``:

```ruby
config.vm.define 'server' do |master|
  master.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end
      
  ...
```
