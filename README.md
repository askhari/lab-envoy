# Overview

This is an _Envoy_ lab deployed using Vagrant.
You may use it to create a simple _Envoy_ mesh and build a playground.

# Requirements

* Virtualbox
* Vagrant

# Set the lab

You will only need to run the following command:

```
$ vagrant up
```

It will prepare three virtual machines with the following software installed:

* _Envoy proxy_
* _Nginx:_ up nad running in port 80 of each node. If you visit the Nginx landing page it will identify the current node where it's running.
* _Extra tools:_ please edit the _Vagrantfile_ and include as many tools as you need.

# Labs

Now you may start playing around with envoy.
There are a few basic _Envoy_ configurations in this repo that you may use to understand a little bit its behaviour. Please remember that _Envoy_ is a **VERY** complete tool. So you may end up haveing also **VERY** complex configurations.

This labs are only an easy approach to have a better understanding of _Envoy_. If you want to learn complex configurations I strongly recommend the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/) or the [Envoy API reference](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api)

# TODO

* Prepare envoy configurations.
