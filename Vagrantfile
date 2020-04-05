# -*- mode: ruby -*-
# vi: set ft=ruby :

# Install envoy and its dependencies.
$installEnvoy = <<SCRIPT
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://getenvoy.io/linux/centos/tetrate-getenvoy.repo
sudo yum-config-manager --enable tetrate-getenvoy-nightly
sudo yum install -y getenvoy-envoy
envoy --version
SCRIPT

# Install nginx to use it as an upstream for envoy.
$installNginx = <<SCRIPT
sudo yum install -y epel-release
sudo yum install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
SCRIPT

# Install your preferred tools to debug and administer this systems.
$installExtraTools = <<SCRIPT
sudo yum install -y vim net-tools
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provision "shell", inline: $installEnvoy
  config.vm.provision "shell", inline: $installNginx
  config.vm.provision "shell", inline: $installExtraTools

  # Generate 3 machines.
  (3..5).each do |i|
    config.vm.define "node-#{i}" do |node|
       node.vm.network "private_network", ip: "172.28.128.#{i}"

       # Configure Nginx index.html
       node.vm.provision "shell",
         inline: "sudo bash -c 'echo Hello from node #{i} > /usr/share/nginx/html/index.html'"
    end
  end
end
