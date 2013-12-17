# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  config.vm.hostname = "balanced-ci-berkshelf"

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "opscode-ubuntu-12.04"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/opscode_ubuntu-12.04_provisionerless.box"

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  #config.vm.network :private_network, ip: "33.33.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.

  # config.vm.network :public_network

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    # vb.gui = true

    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # View the documentation for the provider you're using for more
  # information on available options.

  config.omnibus.chef_version = "11.8.0"

  # The path to the Berksfile to use with Vagrant Berkshelf
  # config.berkshelf.berksfile_path = "./Berksfile"

  # Enabling the Berkshelf plugin. To enable this globally, add this configuration
  # option to your ~/.vagrant.d/Vagrantfile file
  config.berkshelf.enabled = true

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to exclusively install and copy to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  def chef_solo_config(config, *recipes, &block)
    config.vm.provision :chef_solo do |chef|
      chef.log_level = :debug
      chef.json = {
        citadel: {
            access_key_id: ENV['BALANCED_AWS_ACCESS_KEY_ID'] || ENV['AWS_ACCESS_KEY_ID'] || ENV['ACCESS_KEY_ID'],
            secret_access_key: ENV['BALANCED_AWS_SECRET_ACCESS_KEY'] || ENV['AWS_SECRET_ACCESS_KEY'] || ENV['SECRET_ACCESS_KEY'],
          },
        }

      chef.run_list = ['recipe[apt]'] + recipes.map{|r| "recipe[#{r}]"}
      block.call(chef) if block
    end
  end

  config.vm.define 'server' do |master|
    master.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end
    chef_solo_config(master, 'balanced-ci::server') do |chef|
      chef.json['ci'] = {server_hostname: 'ci.dev'}
    end
    master.vm.network :private_network, ip: "10.2.3.4"
  end

  config.vm.define 'builder' do |builder|
    chef_solo_config(builder, 'balanced-ci::balanced') do |chef|
      chef.json['ci'] = {server_url: 'http://10.2.3.4:8080/'}
    end
    builder.vm.network :private_network, ip: "10.2.3.5"
  end

end
