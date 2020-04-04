# -*- mode: ruby -*-
# vi: set ft=ruby :

$installEnvoy = <<SCRIPT
sudo yum install -y yum-utils vim net-tools
sudo yum-config-manager --add-repo https://getenvoy.io/linux/centos/tetrate-getenvoy.repo
sudo yum-config-manager --enable tetrate-getenvoy-nightly
sudo yum install -y getenvoy-envoy
envoy --version
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provision "shell", inline: $installEnvoy

  # Generate 3 machines.
  (3..5).each do |i|
    config.vm.define "node-#{i}" do |node|
       node.vm.network "private_network", ip: "172.28.128.#{i}"
    end
  end
end
