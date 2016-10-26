# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  # Default Ubuntu Box
  config.vm.box = "ubuntu/trusty64"

  # VirtualBox Configuration
  config.vm.provider :virtualbox do |v|
    v.customize ['modifyvm', :id, '--name', 'trusty-devbox']
    v.customize ['modifyvm', :id, '--memory', '4096']
    v.customize ["modifyvm", :id, "--cpus", "2"]

    v.gui = true
    v.customize ['modifyvm', :id, '--vram', '16']
    # v.customize ['modifyvm', :id, '--accelerate3d', 'on']
    v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    v.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
    v.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]

    # Fix for slow external network connection
    v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    v.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
    v.customize ["modifyvm", :id, "--cpuexecutioncap", "80"]

    # Set the box name in VirtualBox to match the working directory
    # v_pwd = Dir.pwd
    # v.name = File.basename(v_pwd)
  end

  # SSH Agent Forwarding
  #
  # Enable agent forwarding on vagrant ssh commands. This allows you to use ssh
  # keys on your host machine inside the guest. See the manual for `ssh-add`.
  config.ssh.forward_agent = true
  # config.ssh.private_key_path = "srv/keys/vagrant"
  # config.ssh.insert_key = false

  config.vm.hostname = "xenial-box"

  # Private Network
  config.vm.network :private_network, id: "devbox_primary", ip: "10.0.0.20"

  # Public Network
  # config.vm.network "public_network",
  #     bridge: "en1: Wi-Fi (AirPort)",
  #     use_dhcp_assigned_default_route: true

  # Port Forwarding
  # config.vm.network :forwarded_port, guest: 8080, host: 8080

  # Drive Mapping
  config.vm.synced_folder "srv", "/srv"
    # :nfs => true,
    # :mount_options => ['actimeo=2']


  # config.vm.provision :shell do |shell|
  #   shell.inline = "
  #     cat /srv/config/ssh/vagrant.pub >> ~root/.ssh/authorized_keys
  #     cat /srv/config/ssh/vagrant.pub >> /home/vagrant/.ssh/authorized_keys
  #   "
  # end
  # Provisions
  #
  config.vm.provision :shell, :path => "provision/bootstrap.sh"
  # config.vm.provision :shell, :path => "patch.sh"

  # config.vm.provision :shell do |shell|
  #   shell.inline = "
  #     apt-get install -y puppet
  #     mkdir -p /etc/puppet/modules
  #     puppet module install puppetlabs-stdlib --force
  #   "
  # end

  #
  # config.vm.provision :puppet do |puppet|
  #   puppet.manifests_path = "puppet/manifests"
  #   puppet.manifest_file = "devbox.pp"
  #   puppet.module_path = "puppet/modules"
  #   puppet.options = "--verbose"
  # end

end
