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

# Install envoy and its dependencies.
$installConsul = <<SCRIPT
sudo mkdir /opt/consul
sudo chown vagrant:vagrant /opt/consul
cd /opt/consul
mkdir bin lib logs config
cd bin
curl -O https://releases.hashicorp.com/consul/1.7.2/consul_1.7.2_linux_amd64.zip
unzip consul_1.7.2_linux_amd64.zip
rm consul_1.7.2_linux_amd64.zip
SCRIPT

# Install your preferred tools to debug and administer this systems.
$installExtraTools = <<SCRIPT
sudo yum install -y vim net-tools strace
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provision "shell", inline: $installEnvoy
  config.vm.provision "shell", inline: $installNginx
  config.vm.provision "shell", inline: $installExtraTools
  config.vm.provision "file", source: "./lab1_plain_text_config", destination: "/home/vagrant/configuration_for_labs/"
  config.vm.provision "file", source: "./lab2_integrating_consul_and_envoy", destination: "/home/vagrant/configuration_for_labs/"

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
