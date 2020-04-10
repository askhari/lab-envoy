# Overview

Hi there

In this repository you'll find some labs that may help understand a little bit the basics on how to use _[Envoy](https://www.envoyproxy.io/)_ with different control planes like _[Consul](https://www.consul.io/)_.
Now, let's get started.

# Goal

The main goal of these labs is to have a better understanding of _[Envoy](https://www.envoyproxy.io/)_ and how to integrate it with some of the current _Service discovery_ softwares in order to migrate from Virtual Machine ecosystem to a Container ecosystem.
Running all these tools by hand will let you understand which challenges you will face when you deal with mixed infrastructures during a migration.

Also, I realized that most tutorials or demonstrations on how to implement and use these softwares are usually based on a final stage, but lack some explanations of all the painful stories in between a migration from old and big architectures to modern ones.

And finally, I'd like to contribute my 2 cents to the community which always helps.

## What this labs are not

This repository contains simple labs.
Please remember that _[Envoy](https://www.envoyproxy.io/)_, _[Consul](https://www.consul.io/)_ and other tools used in these labs are **VERY** complex. These labs are not an explanation on how to use these tools but an approximation on how they work to understand them. 

# Requirements

The lab environment is created using Vagrant over Virtualbox. So you will need some tools installed in your computer.
Also, even it's not mandatory, if you already have some knowledge about _[Envoy](https://www.envoyproxy.io/)_ and _Service discovery_ tools like _[Consul](https://www.consul.io/)_ it may help.

## Tools

* _Linux OS:_ Actually I'm using _[Debian](https://www.debian.org/)_, but any linux distro will do the job. If you don't use linux, you may need to tweak the _Vagrantfile_ provided in this repository.
* _[Virtualbox](https://www.virtualbox.org/wiki/Linux_Downloads):_ Used by _Vagrant_ to create the lab Virtual Machines.
* _[Vagrant](https://www.vagrantup.com/downloads.html):_ this is an awesome tool by _[Hashicorp](https://www.hashicorp.com/)_ used to set up development environments easily.

# Useful documentation

Below there is a list of some documentation that may help during these labs.

* _[Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/)_
* _[Envoy API reference](https://www.envoyproxy.io/docs/envoy/latest/api/api)_
* _[Consul documentation](https://www.consul.io/docs/index.html)_
* _[Consul learning labs](https://learn.hashicorp.com/consul)_
* _[Nginx](https://www.nginx.com/)_

All the software above is used either to set up the lab or to practice with its configuration.

# Labs folder structure

You'll find some labs in this repository. Each lab has the following file/directory structure:

* _README.md_: to explain the lab and its contents and details.
* _Configuration folders_: you may find some folders which contain configuration files for each tool used in the laboratory. For example an _envoy_ or _consul_ folder with some configuration files that you should use in the lab to run them.

Right now this repository have the labs listed below:

* _[lab1_plain_text_config](./lab1_plain_text_config/README.md)_: where you'll configure _[Envoy](https://www.envoyproxy.io/)_ using a static configuration file.
* _[lab2_integrating_consul_and_envoy](./lab2_integrating_consul_and_envoy/README.md)_: where you will run _[Consul](https://www.consul.io/)_ and _[Envoy](https://www.envoyproxy.io/)_ together.

# Set the lab

You will only need to run the following command:

``` bash
$ vagrant up
```

It will prepare three virtual machines with the following software installed:

* _[Envoy](https://www.envoyproxy.io/)_: you'll find it installed at _/opt/getenvoy_ folder
* _[Nginx](https://www.nginx.com/)_: up and running in port 80 of each node.
* _Extra tools:_ like _strace, netstat, net-tools or vim_, please edit the _Vagrantfile_ and include or change them for any tools you are comfortable with.

Once the lab is up and running you may _SSH_ to the nodes:

```bash
ζ vagrant status
Current machine states:

node-3                    running (virtualbox)
node-4                    running (virtualbox)
node-5                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.

ζ # SSH into node-3
ζ vagrant ssh node-3
Last login: Thu Apr  9 19:05:29 2020 from 10.0.2.2
[vagrant@localhost ~]$ cd /opt/consul/bin/
[vagrant@localhost bin]$ ls
consul
```

# TODO

* Prepare README.md's and detailed information for lab1.