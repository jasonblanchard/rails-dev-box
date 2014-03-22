Vagrant::Config.run do |config|
  config.vm.box       = 'precise32'
  config.vm.box_url   = 'http://files.vagrantup.com/precise32.box'
  config.vm.host_name = 'rails-dev-box'
  config.vm.customize ["modifyvm", :id, "--memory", 2048]
  config.vm.customize ["modifyvm", :id, "--cpus", '2']
  config.vm.customize ["modifyvm", :id, "--ioapic", 'on']
  #config.vm.boot_mode = :gui


  #config.vm.forward_port 3000, 3000
  config.vm.network :hostonly, "33.33.33.10"
  config.vm.share_folder("vagrant-root", "/vagrant", ".", :nfs => true)
  config.vm.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]

  config.vm.share_folder("vagrant-root", "/vagrant", ".")

  config.vm.provision :puppet,
    :manifests_path => 'puppet/manifests',
    :module_path    => 'puppet/modules'
end
