# Running Consul

In this lab you will run _Consul_ and _Envoy_ together.
The goal of this lab is to proxy a clients requests to Nginx clients.

# Requirements

You will need to prepare configuration files for each node to run _Consul_ and _Envoy_.
To do this you may use the configuration files provided in this lab.

Please keep in mind that even it's possible to prepare all of this stuff automatically, the main goal of this lab is getting used to configure and run these tools. This will help you to have a better understanding of what's happening under the hoods.

# Configuring Consul

You'll find a _Consul_ binary installed in */opt/consul/bin*.
Please take a look to the configuration files provider in this repository. These files configures _Consul_ to use its _Connect_ features and also registers two services.

## Services registered

There are two services to register in the configuration files:

1. _nginx:_ which is the service that will serve HTTP requests.
2. _client:_ which is used to proxy all the HTTP request to the _nginx_ servers.

# Caveats

## Consul uses an Envoy instance per sidecar-proxy

Each service registered using _Connect-proxy_ will need a unique _Envoy_ instance. This is quite useful in a container ecosystem, but it's quite painful to configure in VM ecosystems.
The reason is that usually in VM ecosystems _Envoy_ is used as a proxy for all the services in the machine.

Take a look to this thread for a better undertanding on why is designed this way: [https://github.com/hashicorp/consul/issues/5388](https://github.com/hashicorp/consul/issues/5388)

## Running multiple Envoy instances

In order to run multiple _Envoy_ instances you will need to use the *--bind-id* parameter.
Also, if you are running multiple _Envoy_ instances, you'll need to change the _admin_ port.

```
envoy -c /tmp/envoy_config.json --base-id 1
```
