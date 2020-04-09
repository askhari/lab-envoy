# First envoy configuration

All virtual machines in this lab have a Nginx web server running.
In this lab you will configure _Envoy_ to proxy and balance the traffic between all the virtual machines.

# Envoy configuration

To run Envoy as a proxy between all the running instances you may use the configuration file *envoy_config.yaml*.
This file contains a basic configuration you will need to adjust for each node.

The values you will need to change relates to:

* IP address of the node.
* Name of the node.

# Running Envoy

Once you have configure _Envoy_, you may run an instance using the configuration file.

```
```
