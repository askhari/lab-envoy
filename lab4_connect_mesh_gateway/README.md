# Lab4: Configuring Consul mesh gateway

In this lab you will:

* Deploy a _[kubernetes](https://kubernetes.io/)_ cluster using _[kind](https://kind.sigs.k8s.io/)_.
* Generate four Virtual Machines using _[Vagrant](https://www.vagrantup.com/)_.
* Create a _[Consul](https://www.consul.io/)_ cluster in the _[kubernetes](https://kubernetes.io/)_ cluster using _[Helm](https://helm.sh/)_.
* Create a _[Consul](https://www.consul.io/)_ cluster in the Virtual Machines created by _[Vagrant](https://www.vagrantup.com/)_.
* Configure a *[Consul mesh gateway](https://www.consul.io/docs/connect/mesh_gateway.html)* in one of the Virtual Machines.
* Configure another *[Consul mesh gateway](https://www.consul.io/docs/connect/mesh_gateway.html)* in the kubernetes cluster.
* Connect both *[Consul mesh gateways](https://www.consul.io/docs/connect/mesh_gateway.html)* to talk to each other.
* Test _[Consul Connect](https://www.consul.io/docs/connect/index.html)_ intentions between clusters via mesh gateways.

# Lab Goal

At the end of this lab you should have a better understanding on:

* How to connect service meshes.
* What is a mesh gateway.
* How services communicate to each other through different service meshes.
* Get a grip on how _[Consul](https://www.consul.io/)_ works on kubernetes clusters.

# Requirements

* Understanding of labs 1, 2 and 3 contents.
* Vagrant set up running.
* Some basic knowledge on _[kubernetes](https://kubernetes.io/)_.
* Some basic knowledge about networking.
* _[Helm](https://helm.sh/)_. 

-------------------------------------------------------------------
Steps:
1. Deploy kind cluster.
2. Wake up Vagrant environment.
3. Deploy consul cluster using _[Helm](https://helm.sh/)_ chart [consul-helm](https://github.com/hashicorp/consul-helm.git) repository. Set *primary_datacenter_* to the consul datacenter you want to be the main one. This is a requirement to issue certificates for mTLS configuration in Envoy sidecars. Also change *values.yaml* file to comment out *affinities, change the datacenter name, add extraConfig for primary datacenter, and reduce replicas for mesh gateway*. *primary_datacenter* Consul configuration should be added to all consul servers and clients. In kubernetes all the services are registered to the consul agent run as a daemon set and then the consul-k8s *lifecycle-service* container registers the service into the agent.
4. Configure Consul cluster in Virtual machines. Configure the primary datacenter also in the Consul cluster configuration.
5. Add some routes to your host to allow visibility between the kubernetes cluster pods and Virtual machines. This is needed to test the Consul Federation. (ip route add 10.244.0.0/24 via 172.26.0.2 src 172.26.0.1)
6. Federate the cluster.
7. Install *counting* and *dashboard* applications to test the service mesh in the kubernetes cluster.
8. Configure the *client* (netcat service) service in one of the Virtual Machines.
9. Test the connection to the *counting* service through the *client* service.
10. Validate that intentions works through different clusters: *consul intention create client counting* 
-------------------------------------------------------------------

# Preliminar explanations

## About service mesh gateways

There are plenty information about mesh gateways if you Google a bit, but right take a look to the [Consul mesh gateway](https://www.consul.io/docs/connect/mesh_gateway.html) documentation to get a grasp on what it is and how is used.

Briefly, a mesh gateway would be the main door for the outgoing and incoming traffic of your service mesh. So, if you want service A from service mesh _"primary"_ talk to service B from service mesh _"secondary"_, those service meshes would have a _mesh gateway_ each one responsable of managing the traffic.
And all these stuff is done usually in a secure way using mTLS. It's just amazing :).

# Installing Helm

You'll need _[Helm](https://helm.sh/)_ for this lab. So please take a look to [this link](https://helm.sh/docs/intro/install/) and download the latest version of _[Helm](https://helm.sh/)_. 

# Creating a Kubernetes cluster using Kind

I used _[kind](https://kind.sigs.k8s.io/)_ to deploy a local kubernetes cluster for this lab, but please use the tool that best suits you.

To create a cluster using _[kind](https://kind.sigs.k8s.io/)_ execute the following command:

```
(⎈ kind-consul-gateway:consul) ζ kind create cluster --name consul-gateway
```

This will take a few minutes to create the cluster, so please be patient.
Once you have the kubernetes cluster created you may continue deploying _[Consul](https://www.consul.io/)_. 


# Configuring Consul

In this lab there are two Consul clusters:

1. _In kubernetes_: which is called _area51playground_ and will be the _secondary_ cluster.
2. _In Virtual Machines_: is the current _Consul cluster_ deployed in the previous labs. It will be set as the _primary_ cluster.

## Deploying the Consul cluster in kubernetes

Here are the steps to deploy the cluster:

1. _Clone the [consul-helm](https://github.com/hashicorp/consul-helm.git) repository_: The URL is this one [https://github.com/hashicorp/consul-helm.git](https://github.com/hashicorp/consul-helm.git).
2. _Make changes in the values.yaml file_: this is done set the appropiate config for the cluster. You may use the [values.yaml](./consul-helm/values.yaml) to configure the helm chart.


```
(⎈ kind-consul-gateway:consul) ζ git clone https://github.com/hashicorp/consul-helm.git
Cloning into 'consul-helm'...
remote: Enumerating objects: 21, done.
remote: Counting objects: 100% (21/21), done.
remote: Compressing objects: 100% (17/17), done.
remote: Total 2679 (delta 9), reused 7 (delta 4), pack-reused 2658
Receiving objects: 100% (2679/2679), 871.77 KiB | 1.35 MiB/s, done.
Resolving deltas: 100% (2053/2053), done.

(⎈ kind-consul-gateway:consul) ζ cd consul-helm

(⎈ kind-consul-gateway:consul) ζ cp ../askharilabs/labs_and_tutorials/envoy/lab4_connect_mesh_gateway/consul-helm/values.yaml .

# Now a git diff to see the differences from the original one.
(⎈ kind-consul-gateway:consul) ζ git diff -U0 | cat                                                                                                                                                     [4833496] 
diff --git a/values.yaml b/values.yaml
index 50fb602..371f0de 100644
--- a/values.yaml
+++ b/values.yaml
@@ -62 +62 @@ global:
-  datacenter: dc1
+  datacenter: area51playground
@@ -225 +225 @@ server:
-  storage: 10Gi
+  storage: 1Gi
@@ -256 +256 @@ server:
-    {}
+    { "primary_datacenter": "envoy-lab" }
@@ -272,9 +272,10 @@ server:
-  affinity: |
-    podAntiAffinity:
-      requiredDuringSchedulingIgnoredDuringExecution:
-        - labelSelector:
-            matchLabels:
-              app: {{ template "consul.name" . }}
-              release: "{{ .Release.Name }}"
-              component: server
-          topologyKey: kubernetes.io/hostname
+  affinity: {}
+  #affinity: |
+  #  podAntiAffinity:
+  #    requiredDuringSchedulingIgnoredDuringExecution:
+  #      - labelSelector:
+  #          matchLabels:
+  #            app: {{ template "consul.name" . }}
+  #            release: "{{ .Release.Name }}"
+  #            component: server
+  #        topologyKey: kubernetes.io/hostname
@@ -368 +369 @@ client:
-  enabled: "-"
+  enabled: true
@@ -401 +402 @@ client:
-    {}
+    { "primary_datacenter": "envoy-lab" }
@@ -525 +526 @@ ui:
-    type: null
+    type: NodePort
@@ -680 +681 @@ connectInject:
-  enabled: false
+  enabled: true
@@ -845 +846 @@ meshGateway:
-  enabled: false
+  enabled: true
@@ -858 +859 @@ meshGateway:
-  replicas: 2
+  replicas: 1
@@ -898 +899 @@ meshGateway:
-    type: LoadBalancer
+    type: NodePort
@@ -907 +908 @@ meshGateway:
-    nodePort: null
+    nodePort: 30500
@@ -960,9 +961,10 @@ meshGateway:
-  affinity: |
-    podAntiAffinity:
-      requiredDuringSchedulingIgnoredDuringExecution:
-        - labelSelector:
-            matchLabels:
-              app: {{ template "consul.name" . }}
-              release: "{{ .Release.Name }}"
-              component: mesh-gateway
-          topologyKey: kubernetes.io/hostname
+  affinity: {}
+  #affinity: |
+  #  podAntiAffinity:
+  #    requiredDuringSchedulingIgnoredDuringExecution:
+  #      - labelSelector:
+  #          matchLabels:
+  #            app: {{ template "consul.name" . }}
+  #            release: "{{ .Release.Name }}"
+  #            component: mesh-gateway
+  #        topologyKey: kubernetes.io/hostname
```

Main changes are:

* Comment out _affinities_: otherwise we would need a local kubernetes cluster with multiple workers. This change is just to keep the local environment small.
* Set _Consul datacenter_ name. I used _area51playground_ as a name for this cluster, but you may use any other name.
* Storage for the instances: set to 1GB. This is also to keep the local environment small.
* Extra services enabled (set to _true_).
  * _client:_ you will need a _Consul agent_ in order to register services automatically using pod injection.
  * _meshGateway:_ this is the _gateway_ we'll configure to channel all our outbound traffic to the _envoy-lab_ _Consul_ cluster. I also reduced the number of replicas of the gateway to reduce resource comsuption.
* Service types changed from _LoadBalancer_ to _NodePort_: we are using a local environment, so chances are we do not have any controller to create a local load balancer.
* Extra configuration for _Consul agents_: in order to interconnect multiple _Consul datacenters_ and _mesh gateways_ you'll need to configure the parameter *primary_datacenter* in the _Consul agent_ configuration. This should be done in agents running as servers or clients and is used to manage ACLs and certificates for the service mesh.

Now lets deploy that _Consul cluster_. You'll need to follow these steps:

1. Create the _consul_ namespace.
2. Execute _Helm_ to deploy the cluster.

```
# Create the namespace.
(⎈ kind-consul-gateway:consul) ζ kubectl create ns consul
(⎈ kind-consul-gateway:consul) ζ kubectl describe ns consul                                                                                                                                             [4833496] 
Name:         consul
Labels:       <none>
Annotations:  <none>
Status:       Active

No resource quota.

No resource limits.

# Create the Consul cluster.
(⎈ kind-consul-gateway:consul) ζ helm install consul --namespace consul . 
(⎈ kind-consul-gateway:consul) ζ helm status consul                                                                                                                                                     [4833496] 
NAME: consul
LAST DEPLOYED: Wed May  6 12:17:19 2020
NAMESPACE: consul
STATUS: deployed
REVISION: 6
NOTES:
Thank you for installing HashiCorp Consul!

Now that you have deployed Consul, you should look over the docs on using 
Consul with Kubernetes available here: 

https://www.consul.io/docs/platform/k8s/index.html


Your release is named consul.

To learn more about the release if you are using Helm 2, run:

  $ helm status consul
  $ helm get consul

To learn more about the release if you are using Helm 3, run:

  $ helm status consul
  $ helm get all consul

```

Once _[Helm](https://helm.sh/)_ finishes its job, you should have the following elements in the _consul_ namespace of your kubernetes cluster:

* _3 Consul servers:_ these build up the _Consul cluster.
* _1 Consul connect injector:_ it's used to inject all the pods needed to configure consul and register the service when the right annotation is added to a _namespace_ or a _pod_.
* _1 Consul agent (client):_ it's deployed as a _daemonset_ and is used to register all the services through injection.
* _1 mesh gateway:_ used for all the outbound traffic of the mesh services that should reach another mesh.
 

Here you may have a quick peek of the kubernetes objects created:
```
(⎈ kind-consul-gateway:consul) ζ k get all                                                                                                                                                              [1da3620] 
NAME                                                                  READY   STATUS    RESTARTS   AGE
pod/consul-consul-connect-injector-webhook-deployment-757c76f9gjtbc   1/1     Running   11         6d21h
pod/consul-consul-mesh-gateway-6d4d4478f5-dt9kn                       2/2     Running   0          6d21h
pod/consul-consul-server-0                                            1/1     Running   0          3d4h
pod/consul-consul-server-1                                            1/1     Running   0          3d4h
pod/consul-consul-server-2                                            1/1     Running   0          3d4h
pod/consul-consul-stwxr                                               1/1     Running   0          3d3h


NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                   AGE
service/consul-consul-connect-injector-svc   ClusterIP   10.96.167.104   <none>        443/TCP                                                                   6d21h
service/consul-consul-dns                    ClusterIP   10.96.169.202   <none>        53/TCP,53/UDP                                                             6d21h
service/consul-consul-mesh-gateway           NodePort    10.96.244.186   <none>        443:30500/TCP                                                             6d21h
service/consul-consul-server                 ClusterIP   None            <none>        8500/TCP,8301/TCP,8301/UDP,8302/TCP,8302/UDP,8300/TCP,8600/TCP,8600/UDP   6d21h
service/consul-consul-ui                     NodePort    10.96.132.87    <none>        80:30998/TCP                                                              6d21h

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/consul-consul   1         1         1       1            1           <none>          6d21h

NAME                                                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/consul-consul-connect-injector-webhook-deployment   1/1     1            1           6d21h
deployment.apps/consul-consul-mesh-gateway                          1/1     1            1           6d21h

NAME                                                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/consul-consul-connect-injector-webhook-deployment-757c76f95   1         1         1       6d21h
replicaset.apps/consul-consul-mesh-gateway-6d4d4478f5                         1         1         1       6d21h

NAME                                    READY   AGE
statefulset.apps/consul-consul-server   3/3     6d21h
```

## Services configured in this lab

You will deploy two services in kubernetes that will register to the Consul cluster:

1. [counting](./consul_services/counter.yaml): a counter that increases each time you visit its endpoint.
2. [dashboard](./consul_services/dashboard.yaml): a simple web application that shows the _counting service_ result.

These two services belong to the [Consul Connect services tutorial](https://learn.hashicorp.com/consul/developer-mesh/connect-services).
They are modified to add an annotation that use the _Consul injection_ feature.

In order to deploy them use the following commands:

```
(⎈ kind-consul-gateway:consul) ζ kubectl apply -f counter.yaml
(⎈ kind-consul-gateway:consul) ζ kubectl apply -f dashboard.yaml
```

Now let's take a look to one of those pods and learn what happened:

```
# Get dashboard pod
(⎈ kind-consul-gateway:consul) ζ k get pod -n default dashboard                                                                                                                                         [1da3620] 
NAME        READY   STATUS    RESTARTS   AGE
dashboard   3/3     Running   0          3d21h

# Describe dasboard pod details
(⎈ kind-consul-gateway:consul) ζ k describe pod dashboard -n default                                                                                                                                    [1da3620] 
Name:         dashboard
Namespace:    default
Priority:     0
Node:         consul-gateway-control-plane/172.26.0.2
Start Time:   Tue, 05 May 2020 18:32:10 +0200
Labels:       app=dashboard
Annotations:  consul.hashicorp.com/connect-inject: true
              consul.hashicorp.com/connect-inject-status: injected
              consul.hashicorp.com/connect-service: dashboard
              consul.hashicorp.com/connect-service-port: http
              consul.hashicorp.com/connect-service-upstreams: counting:9001
              kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{"consul.hashicorp.com/connect-inject":"true","consul.hashicorp.com/connect-serv...
Status:       Running
IP:           10.244.0.17
Init Containers:
  consul-connect-inject-init:
    Container ID:  containerd://1123c921fa92009ff4c734ccc97eb348ed4d99dea5a3846867c13334acd0aee5
    Image:         consul:1.7.2
    Image ID:      docker.io/library/consul@sha256:4592d81f9cecdc9fe1832bdcd22dfceafd36720011539679ae177f62cf169ce6
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
      -ec
      
      export CONSUL_HTTP_ADDR="${HOST_IP}:8500"
      export CONSUL_GRPC_ADDR="${HOST_IP}:8502"
      
      # Register the service. The HCL is stored in the volume so that
      # the preStop hook can access it to deregister the service.
      cat <<EOF >/consul/connect-inject/service.hcl
      services {
        id   = "${PROXY_SERVICE_ID}"
        name = "dashboard-sidecar-proxy"
        kind = "connect-proxy"
        address = "${POD_IP}"
        port = 20000
      
        proxy {
          destination_service_name = "dashboard"
          destination_service_id = "${SERVICE_ID}"
          local_service_address = "127.0.0.1"
          local_service_port = 9002
          upstreams {
            destination_type = "service" 
            destination_name = "counting"
            local_bind_port = 9001
          }
        }
      
        checks {
          name = "Proxy Public Listener"
          tcp = "${POD_IP}:20000"
          interval = "10s"
          deregister_critical_service_after = "10m"
        }
      
        checks {
          name = "Destination Alias"
          alias_service = "dashboard"
        }
      }
      
      services {
        id   = "${SERVICE_ID}"
        name = "dashboard"
        address = "${POD_IP}"
        port = 9002
      }
      EOF
      
      /bin/consul services register \
        /consul/connect-inject/service.hcl
      
      # Generate the envoy bootstrap code
      /bin/consul connect envoy \
        -proxy-id="${PROXY_SERVICE_ID}" \
        -bootstrap > /consul/connect-inject/envoy-bootstrap.yaml
      
      # Copy the Consul binary
      cp /bin/consul /consul/connect-inject/consul
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Tue, 05 May 2020 18:32:11 +0200
      Finished:     Tue, 05 May 2020 18:32:12 +0200
    Ready:          True
    Restart Count:  0
    Environment:
      HOST_IP:            (v1:status.hostIP)
      POD_IP:             (v1:status.podIP)
      POD_NAME:          dashboard (v1:metadata.name)
      POD_NAMESPACE:     default (v1:metadata.namespace)
      SERVICE_ID:        $(POD_NAME)-dashboard
      PROXY_SERVICE_ID:  $(POD_NAME)-dashboard-sidecar-proxy
    Mounts:
      /consul/connect-inject from consul-connect-inject-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from dashboard-token-chdw4 (ro)
Containers:
  dashboard:
    Container ID:   containerd://c30de0e6fc6aa2697e4d01306a5d00b87676bff9c05f825db848260fe30a562c
    Image:          hashicorp/dashboard-service:0.0.4
    Image ID:       docker.io/hashicorp/dashboard-service@sha256:1361b8d702e96603f35d7f170fedcd50ee62aa864330d87faa1bc9a94b6cc7da
    Port:           9002/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 05 May 2020 18:32:17 +0200
    Ready:          True
    Restart Count:  0
    Environment:
      COUNTING_SERVICE_URL:           http://localhost:9001
      COUNTING_CONNECT_SERVICE_HOST:  127.0.0.1
      COUNTING_CONNECT_SERVICE_PORT:  9001
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from dashboard-token-chdw4 (ro)
  consul-connect-envoy-sidecar:
    Container ID:  containerd://f81f9f9a81ae99b3b6b15bfa7104b95534df6f0adff01105a54d815ad19784ff
    Image:         envoyproxy/envoy-alpine:v1.13.0
    Image ID:      docker.io/envoyproxy/envoy-alpine@sha256:19f3b361450e31f68b46f891b0c8726041739f44ab9b90aecbca5f426c0d2eaf
    Port:          <none>
    Host Port:     <none>
    Command:
      envoy
      --max-obj-name-len
      256
      --config-path
      /consul/connect-inject/envoy-bootstrap.yaml
    State:          Running
      Started:      Tue, 05 May 2020 18:32:17 +0200
    Ready:          True
    Restart Count:  0
    Environment:
      HOST_IP:            (v1:status.hostIP)
      CONSUL_HTTP_ADDR:  $(HOST_IP):8500
    Mounts:
      /consul/connect-inject from consul-connect-inject-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from dashboard-token-chdw4 (ro)
  consul-connect-lifecycle-sidecar:
    Container ID:  containerd://2d4c42a307a71027b8ff3385061445ca030cedd58bd1b34a95797ccf6d3e082a
    Image:         hashicorp/consul-k8s:0.14.0
    Image ID:      docker.io/hashicorp/consul-k8s@sha256:bc368a7339777bcfe40ca25c918cac17e65ca2cec41afe7f9c603b6bf8c36e2f
    Port:          <none>
    Host Port:     <none>
    Command:
      consul-k8s
      lifecycle-sidecar
      -service-config
      /consul/connect-inject/service.hcl
      -consul-binary
      /consul/connect-inject/consul
    State:          Running
      Started:      Tue, 05 May 2020 18:32:17 +0200
    Ready:          True
    Restart Count:  0
    Environment:
      HOST_IP:            (v1:status.hostIP)
      CONSUL_HTTP_ADDR:  $(HOST_IP):8500
    Mounts:
      /consul/connect-inject from consul-connect-inject-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from dashboard-token-chdw4 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  dashboard-token-chdw4:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  dashboard-token-chdw4
    Optional:    false
  consul-connect-inject-data:
    Type:        EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:      
    SizeLimit:   <unset>
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>
```

Wow! That output is huge! Let's take a closer look to the containers within it.
These pod has _Init_ and _normal_ containers. _Init_ containers are used to prepare the environment for the main containers that run in the pod.

**Init containers:**

* _consul-connect-inject-init:_ this is an injected container that has a few duties:
  * Generates the _Consul_ configuration file used to register the service and stores it in a volume (Empty dir).
  * Registers the service in _Consul_.
  * Generates the Envoy configuration used to run _Consul Connect_ as a sidecar container and stores it in a volume.

**Main containers:**

* _dashboard_: this is the application container which is the only one defined in the kubernetes manifest.
* _consul-connect-envoy-sidecar_: this is an _Envoy proxy_ instance that bootstrap using the configuration generated by the *consul-connect-inject-init* container.
* _consul-connect-lifecycle-sidecar_: it's a sidecar container that ensures that the service is registered in consul properly. This is needed in case the _Consul_ agent dies.

As you may noticed, this is a lot of stuff for just one pod. But, how can we wrap up all the pieces together? And which is the workflow used to configure all this stuff?
Well, let's make a quick summary of the steps at this point:

1. You have a _Consul Cluster_.
2. You configured the cluster to support _Consul Connect_. This enables the service mesh.
3. You configured the _Consul injector_. This allows you to use the **"consul.hashicorp.com/connect-inject": "true"** and **"consul.hashicorp.com/connect-service-upstreams": "counting:9001"** annotations in the dashboard pod configuration.
4. You also deployed a _Consul agent_ as a _daemonset_ that is used to register any service 
5. You deployed the _dashboard_ application using the **"consul.hashicorp.com/connect-inject": "true"** and **"consul.hashicorp.com/connect-service-upstreams": "counting:9001"** annotations. This allows the _Consul injector_ to take action and add the *consul-connect-inject-init*, *consul-connect-envoy-sidecar* and *consul-connect-lifecycle-sidecar* to the pod definition.
6. The *consul-connect-inject-init* container generates the configuration needed by the *consul-connect-envoy-sidecar* and *consul-connect-lifecycle-sidecar* sidecars, and also registers the service into the _Consul agent_.
7. The *consul-connect-envoy-sidecar* boots an _Envoy proxy_ allowing the _Consul_ control plane to send traffic through _Envoy_.
8. The *consul-connect-lifecycle-sidecar* ensures that the _dashboard_ service is properly configured into the _Consul_ cluster.

## Deploying Consul into Virtual Machines

You already have Consul configured in Virtual Machines from previous labs, so I'll skip the basic configuration.

You will need to make some configuration changes to your _Consul servers_ in order to add the *primary_datacenter* configuration parameter.
Please start the changes in the _follower_ servers. To retrieve the list of the servers execute the commands below:

```
[vagrant@localhost ~]$ /opt/consul/bin/consul operator raft list-peers -http-addr=172.28.128.4:8500
Node   ID                                    Address            State     Voter  RaftProtocol
node3  f408575a-88cc-329f-8246-638e81cc6e30  172.28.128.3:8300  leader    true   3
node4  d3f3d9c0-20f3-4043-0e93-534282cbc957  172.28.128.4:8300  follower  true   3
node5  c21dc05c-5968-92ad-6112-a350b7c4b7e8  172.28.128.5:8300  follower  true   3
```

Now choose one of the follower servers and will proceed to configure it as a client for the mesh gateway. In this example I used *node-5*:

```
# Stop consul agent.
$ /opt/consul/bin/consul leave -http-addr=172.28.128.5:8500

# Clean all consul metadata:
$ rm -rf /opt/consul/lib/*
```

Now it's time to configure _Consul_ to run as a client for the _mesh gateway_. To do that:

1. Change the content of the */opt/consul/config/main.hcl* file for this one *[main.hcl](./consul_gateway/main.hcl)*.
2. Remove the content of the */opt/consul/config/services/*.
3. Add the file *[gateway.yaml](./consul_gateway/gateway.yaml)* to the */opt/consul/config/services/* folder.
4. Start Consul again:

Below you'll see the files contents and how to start consul.

```
[root@localhost ~]# cat /opt/consul_client/config/main.hcl 
datacenter = "envoy-lab"
primary_datacenter = "envoy-lab"
server = false
bind_addr = "172.28.128.5"
ports {
  grpc = 8502
}
addresses {
  http = "172.28.128.5"
}
data_dir = "/opt/consul_client/lib"
log_file = "/opt/consul_client/logs/consul.log"
node_name = "node5"
start_join = ["172.28.128.3","172.28.128.4"]
retry_join = ["172.28.128.3","172.28.128.4"]
connect {
  enabled = true
}

[root@localhost ~]# cat /opt/consul_client/config/services/service.hcl 
service {
  kind = "mesh-gateway"
  name = "mesh-gateway"
  port = 8443
  checks = [
    {
      name = "Mesh Gateway Listening"
      interval = "10s"
      tcp = ":8443"
      deregister_critical_service_after = "6h"
    }
  ]
}

[vagrant@localhost services]$ /opt/consul_client/bin/consul agent -config-file /opt/consul_client/config/main.hcl -config-dir /opt/consul_client/config/services/
==> Starting Consul agent...
           Version: 'v1.7.2'
           Node ID: '36817e33-f354-6330-39b6-51664883a8e1'
         Node name: 'node5'
        Datacenter: 'envoy-lab' (Segment: '')
            Server: false (Bootstrap: false)
       Client Addr: [127.0.0.1] (HTTP: 8500, HTTPS: -1, gRPC: 8502, DNS: 8600)
      Cluster Addr: 172.28.128.5 (LAN: 8301, WAN: 8302)
           Encrypt: Gossip: false, TLS-Outgoing: false, TLS-Incoming: false, Auto-Encrypt-TLS: false

==> Log data will now stream in as it occurs:

    2020-05-09T15:43:12.155Z [INFO]  agent.client.serf.lan: serf: EventMemberJoin: node5 172.28.128.5
    2020-05-09T15:43:12.156Z [INFO]  agent: Started DNS server: address=127.0.0.1:8600 network=udp
    2020-05-09T15:43:12.157Z [INFO]  agent: Started DNS server: address=127.0.0.1:8600 network=tcp
    2020-05-09T15:43:12.157Z [INFO]  agent: Started HTTP server: address=172.28.128.5:8500 network=tcp
==> Joining cluster...

```


# What's happening under the hood

Well, you might be wondering how does _[Consul](https://www.consul.io/)_ all this magic.

In fact _[Consul](https://www.consul.io/)_ configures _[Envoy](https://www.envoyproxy.io/)_ adding:

* A new _cluster_ configuration for each entry in the *nginx_splitter.hcl* file.
* One _HTTP_ filter called _envoy.router_ to the _client_ configuration that has the upstreams configured.
* Some *dynamic_route_configs* to balance the traffic between the added _clusters_.

Below you have the complete _[Envoy](https://www.envoyproxy.io/)_ configuration of this example (it's quite long):

```bash
[vagrant@localhost traffic]$ curl http://172.28.128.3:29000/config_dump
{
 "configs": [
  {
   "@type": "type.googleapis.com/envoy.admin.v3.BootstrapConfigDump",
   "bootstrap": {
    "node": {
     "id": "client-sidecar-proxy",
     "cluster": "client",
     "metadata": {
      "namespace": "default",
      "envoy_version": "1.13.0"
     },
     "hidden_envoy_deprecated_build_version": "33197389c9b969f974be85a690113f1b955ad3d7/1.14.0-dev/clean-getenvoy-bd0b7e5-envoy/RELEASE/BoringSSL",
     "user_agent_name": "envoy",
     "user_agent_build_version": {
      "version": {
       "major_number": 1,
       "minor_number": 14
      },
      "metadata": {
       "ssl.version": "BoringSSL",
       "revision.status": "clean-getenvoy-bd0b7e5-envoy",
       "revision.sha": "33197389c9b969f974be85a690113f1b955ad3d7",
       "build.label": "dev",
       "build.type": "RELEASE"
      }
     },
     "extensions": [
      {
       "name": "default",
       "category": "envoy.dubbo_proxy.route_matchers"
      },
      {
       "name": "envoy.transport_sockets.alts",
       "category": "envoy.transport_sockets.upstream"
      },
      {
       "name": "envoy.transport_sockets.raw_buffer",
       "category": "envoy.transport_sockets.upstream"
      },
      {
       "name": "envoy.transport_sockets.tap",
       "category": "envoy.transport_sockets.upstream"
      },
      {
       "name": "envoy.transport_sockets.tls",
       "category": "envoy.transport_sockets.upstream"
      },
      {
       "name": "raw_buffer",
       "category": "envoy.transport_sockets.upstream"
      },
      {
       "name": "tls",
       "category": "envoy.transport_sockets.upstream"
      },
      {
       "name": "raw_udp_listener",
       "category": "envoy.udp_listeners"
      },
      {
       "name": "envoy.access_loggers.file",
       "category": "envoy.access_loggers"
      },
      {
       "name": "envoy.access_loggers.http_grpc",
       "category": "envoy.access_loggers"
      },
      {
       "name": "envoy.access_loggers.tcp_grpc",
       "category": "envoy.access_loggers"
      },
      {
       "name": "envoy.file_access_log",
       "category": "envoy.access_loggers"
      },
      {
       "name": "envoy.http_grpc_access_log",
       "category": "envoy.access_loggers"
      },
      {
       "name": "envoy.tcp_grpc_access_log",
       "category": "envoy.access_loggers"
      },
      {
       "name": "dubbo",
       "category": "envoy.dubbo_proxy.protocols"
      },
      {
       "name": "envoy.transport_sockets.alts",
       "category": "envoy.transport_sockets.downstream"
      },
      {
       "name": "envoy.transport_sockets.raw_buffer",
       "category": "envoy.transport_sockets.downstream"
      },
      {
       "name": "envoy.transport_sockets.tap",
       "category": "envoy.transport_sockets.downstream"
      },
      {
       "name": "envoy.transport_sockets.tls",
       "category": "envoy.transport_sockets.downstream"
      },
      {
       "name": "raw_buffer",
       "category": "envoy.transport_sockets.downstream"
      },
      {
       "name": "tls",
       "category": "envoy.transport_sockets.downstream"
      },
      {
       "name": "envoy.dog_statsd",
       "category": "envoy.stats_sinks"
      },
      {
       "name": "envoy.metrics_service",
       "category": "envoy.stats_sinks"
      },
      {
       "name": "envoy.stat_sinks.dog_statsd",
       "category": "envoy.stats_sinks"
      },
      {
       "name": "envoy.stat_sinks.hystrix",
       "category": "envoy.stats_sinks"
      },
      {
       "name": "envoy.stat_sinks.metrics_service",
       "category": "envoy.stats_sinks"
      },
      {
       "name": "envoy.stat_sinks.statsd",
       "category": "envoy.stats_sinks"
      },
      {
       "name": "envoy.statsd",
       "category": "envoy.stats_sinks"
      },
      {
       "name": "envoy.grpc_credentials.aws_iam",
       "category": "envoy.grpc_credentials"
      },
      {
       "name": "envoy.grpc_credentials.default",
       "category": "envoy.grpc_credentials"
      },
      {
       "name": "envoy.grpc_credentials.file_based_metadata",
       "category": "envoy.grpc_credentials"
      },
      {
       "name": "envoy.filters.udp.dns_filter",
       "category": "envoy.filters.udp_listener"
      },
      {
       "name": "envoy.filters.udp_listener.udp_proxy",
       "category": "envoy.filters.udp_listener"
      },
      {
       "name": "envoy.cluster.eds",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.cluster.logical_dns",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.cluster.original_dst",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.cluster.static",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.cluster.strict_dns",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.clusters.aggregate",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.clusters.dynamic_forward_proxy",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.clusters.redis",
       "category": "envoy.clusters"
      },
      {
       "name": "envoy.health_checkers.redis",
       "category": "envoy.health_checkers"
      },
      {
       "name": "envoy.filters.listener.http_inspector",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.filters.listener.original_dst",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.filters.listener.original_src",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.filters.listener.proxy_protocol",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.filters.listener.tls_inspector",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.listener.http_inspector",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.listener.original_dst",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.listener.original_src",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.listener.proxy_protocol",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.listener.tls_inspector",
       "category": "envoy.filters.listener"
      },
      {
       "name": "envoy.ip",
       "category": "envoy.resolvers"
      },
      {
       "name": "envoy.retry_host_predicates.omit_canary_hosts",
       "category": "envoy.retry_host_predicates"
      },
      {
       "name": "envoy.retry_host_predicates.omit_host_metadata",
       "category": "envoy.retry_host_predicates"
      },
      {
       "name": "envoy.retry_host_predicates.previous_hosts",
       "category": "envoy.retry_host_predicates"
      },
      {
       "name": "envoy.buffer",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.cors",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.csrf",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.ext_authz",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.fault",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.adaptive_concurrency",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.aws_lambda",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.aws_request_signing",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.buffer",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.cache",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.cors",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.csrf",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.dynamic_forward_proxy",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.dynamo",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.ext_authz",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.fault",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.grpc_http1_bridge",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.grpc_http1_reverse_bridge",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.grpc_json_transcoder",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.grpc_stats",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.grpc_web",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.gzip",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.header_to_metadata",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.health_check",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.ip_tagging",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.jwt_authn",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.lua",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.on_demand",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.original_src",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.ratelimit",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.rbac",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.router",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.squash",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.filters.http.tap",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.grpc_http1_bridge",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.grpc_json_transcoder",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.grpc_web",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.gzip",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.health_check",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.http_dynamo_filter",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.ip_tagging",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.lua",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.rate_limit",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.router",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.squash",
       "category": "envoy.filters.http"
      },
      {
       "name": "envoy.extensions.http.cache.simple",
       "category": "http_cache_factory"
      },
      {
       "name": "auto",
       "category": "envoy.thrift_proxy.protocols"
      },
      {
       "name": "binary",
       "category": "envoy.thrift_proxy.protocols"
      },
      {
       "name": "binary/non-strict",
       "category": "envoy.thrift_proxy.protocols"
      },
      {
       "name": "compact",
       "category": "envoy.thrift_proxy.protocols"
      },
      {
       "name": "twitter",
       "category": "envoy.thrift_proxy.protocols"
      },
      {
       "name": "envoy.client_ssl_auth",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.echo",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.ext_authz",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.client_ssl_auth",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.direct_response",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.dubbo_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.echo",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.ext_authz",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.http_connection_manager",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.kafka_broker",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.local_ratelimit",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.mongo_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.mysql_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.ratelimit",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.rbac",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.redis_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.sni_cluster",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.tcp_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.thrift_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.filters.network.zookeeper_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.http_connection_manager",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.mongo_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.ratelimit",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.redis_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "envoy.tcp_proxy",
       "category": "envoy.filters.network"
      },
      {
       "name": "auto",
       "category": "envoy.thrift_proxy.transports"
      },
      {
       "name": "framed",
       "category": "envoy.thrift_proxy.transports"
      },
      {
       "name": "header",
       "category": "envoy.thrift_proxy.transports"
      },
      {
       "name": "unframed",
       "category": "envoy.thrift_proxy.transports"
      },
      {
       "name": "envoy.filters.thrift.rate_limit",
       "category": "envoy.thrift_proxy.filters"
      },
      {
       "name": "envoy.filters.thrift.router",
       "category": "envoy.thrift_proxy.filters"
      },
      {
       "name": "envoy.resource_monitors.fixed_heap",
       "category": "envoy.resource_monitors"
      },
      {
       "name": "envoy.resource_monitors.injected_resource",
       "category": "envoy.resource_monitors"
      },
      {
       "name": "envoy.dynamic.ot",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.lightstep",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.tracers.datadog",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.tracers.dynamic_ot",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.tracers.lightstep",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.tracers.opencensus",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.tracers.xray",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.tracers.zipkin",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.zipkin",
       "category": "envoy.tracers"
      },
      {
       "name": "envoy.retry_priorities.previous_priorities",
       "category": "envoy.retry_priorities"
      },
      {
       "name": "dubbo.hessian2",
       "category": "envoy.dubbo_proxy.serializers"
      },
      {
       "name": "envoy.filters.dubbo.router",
       "category": "envoy.dubbo_proxy.filters"
      }
     ]
    },
    "static_resources": {
     "clusters": [
      {
       "name": "local_agent",
       "type": "STATIC",
       "connect_timeout": "1s",
       "hidden_envoy_deprecated_hosts": [
        {
         "socket_address": {
          "address": "127.0.0.1",
          "port_value": 8502
         }
        }
       ],
       "http2_protocol_options": {}
      }
     ]
    },
    "dynamic_resources": {
     "lds_config": {
      "ads": {}
     },
     "cds_config": {
      "ads": {}
     },
     "ads_config": {
      "api_type": "GRPC",
      "grpc_services": [
       {
        "envoy_grpc": {
         "cluster_name": "local_agent"
        },
        "initial_metadata": [
         {
          "key": "x-consul-token"
         }
        ]
       }
      ]
     }
    },
    "admin": {
     "access_log_path": "/dev/null",
     "address": {
      "socket_address": {
       "address": "172.28.128.3",
       "port_value": 29000
      }
     }
    },
    "stats_config": {
     "stats_tags": [
      {
       "tag_name": "consul.custom_hash",
       "regex": "^cluster\\.((?:([^.]+)~)?(?:[^.]+\\.)?[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.consul\\.)"
      },
      {
       "tag_name": "consul.service_subset",
       "regex": "^cluster\\.((?:[^.]+~)?(?:([^.]+)\\.)?[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.consul\\.)"
      },
      {
       "tag_name": "consul.service",
       "regex": "^cluster\\.((?:[^.]+~)?(?:[^.]+\\.)?([^.]+)\\.[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.consul\\.)"
      },
      {
       "tag_name": "consul.namespace",
       "regex": "^cluster\\.((?:[^.]+~)?(?:[^.]+\\.)?[^.]+\\.([^.]+)\\.[^.]+\\.[^.]+\\.[^.]+\\.consul\\.)"
      },
      {
       "tag_name": "consul.datacenter",
       "regex": "^cluster\\.((?:[^.]+~)?(?:[^.]+\\.)?[^.]+\\.[^.]+\\.([^.]+)\\.[^.]+\\.[^.]+\\.consul\\.)"
      },
      {
       "tag_name": "consul.routing_type",
       "regex": "^cluster\\.((?:[^.]+~)?(?:[^.]+\\.)?[^.]+\\.[^.]+\\.[^.]+\\.([^.]+)\\.[^.]+\\.consul\\.)"
      },
      {
       "tag_name": "consul.trust_domain",
       "regex": "^cluster\\.((?:[^.]+~)?(?:[^.]+\\.)?[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.([^.]+)\\.consul\\.)"
      },
      {
       "tag_name": "consul.target",
       "regex": "^cluster\\.(((?:[^.]+~)?(?:[^.]+\\.)?[^.]+\\.[^.]+\\.[^.]+)\\.[^.]+\\.[^.]+\\.consul\\.)"
      },
      {
       "tag_name": "consul.full_target",
       "regex": "^cluster\\.(((?:[^.]+~)?(?:[^.]+\\.)?[^.]+\\.[^.]+\\.[^.]+\\.[^.]+\\.[^.]+)\\.consul\\.)"
      },
      {
       "tag_name": "local_cluster",
       "fixed_value": "client"
      }
     ],
     "use_all_default_tags": true
    },
    "layered_runtime": {
     "layers": [
      {
       "name": "static_layer",
       "static_layer": {
        "envoy.deprecated_features:envoy.config.trace.v2.ZipkinConfig.HTTP_JSON_V1": true,
        "envoy.deprecated_features:envoy.config.filter.network.http_connection_manager.v2.HttpConnectionManager.Tracing.operation_name": true,
        "envoy.deprecated_features:envoy.api.v2.Cluster.tls_context": true
       }
      }
     ]
    }
   },
   "last_updated": "2020-04-12T18:22:02.352Z"
  },
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ClustersConfigDump",
   "version_info": "00000001",
   "static_clusters": [
    {
     "cluster": {
      "@type": "type.googleapis.com/envoy.api.v2.Cluster",
      "name": "local_agent",
      "type": "STATIC",
      "connect_timeout": "1s",
      "hosts": [
       {
        "socket_address": {
         "address": "127.0.0.1",
         "port_value": 8502
        }
       }
      ],
      "http2_protocol_options": {}
     },
     "last_updated": "2020-04-12T18:22:02.366Z"
    }
   ],
   "dynamic_active_clusters": [
    {
     "version_info": "00000001",
     "cluster": {
      "@type": "type.googleapis.com/envoy.api.v2.Cluster",
      "name": "local_app",
      "type": "STATIC",
      "connect_timeout": "5s",
      "load_assignment": {
       "cluster_name": "local_app",
       "endpoints": [
        {
         "lb_endpoints": [
          {
           "endpoint": {
            "address": {
             "socket_address": {
              "address": "127.0.0.1",
              "port_value": 8080
             }
            }
           }
          }
         ]
        }
       ]
      }
     },
     "last_updated": "2020-04-12T18:22:02.387Z"
    },
    {
     "version_info": "00000001",
     "cluster": {
      "@type": "type.googleapis.com/envoy.api.v2.Cluster",
      "name": "primary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
      "type": "EDS",
      "eds_cluster_config": {
       "eds_config": {
        "ads": {}
       }
      },
      "connect_timeout": "5s",
      "circuit_breakers": {},
      "tls_context": {
       "common_tls_context": {
        "tls_params": {},
        "tls_certificates": [
         {
          "certificate_chain": {
           "inline_string": "-----BEGIN CERTIFICATE-----\nMIICSTCCAe+gAwIBAgIBCjAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDUzN1oX\nDTIwMDQxNTE4MDUzN1owLTErMCkGA1UEAxMiY2xpZW50LnN2Yy5kZWZhdWx0LjFk\nYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABMvzbDE7CXj7\n+DfyI9/WWPXNzYrTalKIVGz1+Ebql52sWe6gVpsQTEoxtM/88td4os1/IxnC7nG/\nW2lV+Lgn3d6jgfwwgfkwDgYDVR0PAQH/BAQDAgO4MB0GA1UdJQQWMBQGCCsGAQUF\nBwMCBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMCkGA1UdDgQiBCDoaeWonBuaDAHv\nMUJ1b2EB83boUURfpQ0/yVTdBlqtDDArBgNVHSMEJDAigCBfHndAYlFpB46JHbcU\nByOHUZEShYhvl+x/x2VR708e+DBiBgNVHREEWzBZhldzcGlmZmU6Ly8xZGI1NGY2\nZi05ZmEwLTVjNWQtNWNmZS1iYzBiOWU2ZGJkNjIuY29uc3VsL25zL2RlZmF1bHQv\nZGMvZW52b3ktbGFiL3N2Yy9jbGllbnQwCgYIKoZIzj0EAwIDSAAwRQIhALq0PokS\nRcjCSGWXVzAjTVPOB3J0wZqJk6HZe/Iyfm3PAiBlxJ5GJFm3emtVzUT+iM39rIET\nDoG/2Uz2st7NrAO8xw==\n-----END CERTIFICATE-----\n"
          },
          "private_key": {
           "inline_string": "[redacted]"
          }
         }
        ],
        "validation_context": {
         "trusted_ca": {
          "inline_string": "-----BEGIN CERTIFICATE-----\nMIICDTCCAbOgAwIBAgIBCDAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDYzNloX\nDTMwMDQxMjE4MDYzNlowMDEuMCwGA1UEAxMlcHJpLWx5N2lxMG0uY29uc3VsLmNh\nLjFkYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAAuUem3\nztCG2lzgB5DOvxDGfuSM+YJ1e3Hed3EWHE6PYlT7TXi9xgGTW2/yKacuYCR3zD8F\no39cqb2siIqYBs+jgb0wgbowDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMB\nAf8wKQYDVR0OBCIEIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MCsG\nA1UdIwQkMCKAIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MD8GA1Ud\nEQQ4MDaGNHNwaWZmZTovLzFkYjU0ZjZmLTlmYTAtNWM1ZC01Y2ZlLWJjMGI5ZTZk\nYmQ2Mi5jb25zdWwwCgYIKoZIzj0EAwIDSAAwRQIgBacTc/BgC+7CkzQWR36uxsQj\nHVxruXfaovikz6pCFegCIQCvufZqQK/mbzH3EZ/2brd63G/LICx+8a64Ge+C1MaM\nLQ==\n-----END CERTIFICATE-----\n"
         }
        }
       },
       "sni": "primary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
      },
      "outlier_detection": {},
      "common_lb_config": {
       "healthy_panic_threshold": {}
      },
      "alt_stat_name": "primary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
     },
     "last_updated": "2020-04-12T18:22:02.398Z"
    },
    {
     "version_info": "00000001",
     "cluster": {
      "@type": "type.googleapis.com/envoy.api.v2.Cluster",
      "name": "secondary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
      "type": "EDS",
      "eds_cluster_config": {
       "eds_config": {
        "ads": {}
       }
      },
      "connect_timeout": "5s",
      "circuit_breakers": {},
      "tls_context": {
       "common_tls_context": {
        "tls_params": {},
        "tls_certificates": [
         {
          "certificate_chain": {
           "inline_string": "-----BEGIN CERTIFICATE-----\nMIICSTCCAe+gAwIBAgIBCjAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDUzN1oX\nDTIwMDQxNTE4MDUzN1owLTErMCkGA1UEAxMiY2xpZW50LnN2Yy5kZWZhdWx0LjFk\nYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABMvzbDE7CXj7\n+DfyI9/WWPXNzYrTalKIVGz1+Ebql52sWe6gVpsQTEoxtM/88td4os1/IxnC7nG/\nW2lV+Lgn3d6jgfwwgfkwDgYDVR0PAQH/BAQDAgO4MB0GA1UdJQQWMBQGCCsGAQUF\nBwMCBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMCkGA1UdDgQiBCDoaeWonBuaDAHv\nMUJ1b2EB83boUURfpQ0/yVTdBlqtDDArBgNVHSMEJDAigCBfHndAYlFpB46JHbcU\nByOHUZEShYhvl+x/x2VR708e+DBiBgNVHREEWzBZhldzcGlmZmU6Ly8xZGI1NGY2\nZi05ZmEwLTVjNWQtNWNmZS1iYzBiOWU2ZGJkNjIuY29uc3VsL25zL2RlZmF1bHQv\nZGMvZW52b3ktbGFiL3N2Yy9jbGllbnQwCgYIKoZIzj0EAwIDSAAwRQIhALq0PokS\nRcjCSGWXVzAjTVPOB3J0wZqJk6HZe/Iyfm3PAiBlxJ5GJFm3emtVzUT+iM39rIET\nDoG/2Uz2st7NrAO8xw==\n-----END CERTIFICATE-----\n"
          },
          "private_key": {
           "inline_string": "[redacted]"
          }
         }
        ],
        "validation_context": {
         "trusted_ca": {
          "inline_string": "-----BEGIN CERTIFICATE-----\nMIICDTCCAbOgAwIBAgIBCDAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDYzNloX\nDTMwMDQxMjE4MDYzNlowMDEuMCwGA1UEAxMlcHJpLWx5N2lxMG0uY29uc3VsLmNh\nLjFkYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAAuUem3\nztCG2lzgB5DOvxDGfuSM+YJ1e3Hed3EWHE6PYlT7TXi9xgGTW2/yKacuYCR3zD8F\no39cqb2siIqYBs+jgb0wgbowDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMB\nAf8wKQYDVR0OBCIEIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MCsG\nA1UdIwQkMCKAIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MD8GA1Ud\nEQQ4MDaGNHNwaWZmZTovLzFkYjU0ZjZmLTlmYTAtNWM1ZC01Y2ZlLWJjMGI5ZTZk\nYmQ2Mi5jb25zdWwwCgYIKoZIzj0EAwIDSAAwRQIgBacTc/BgC+7CkzQWR36uxsQj\nHVxruXfaovikz6pCFegCIQCvufZqQK/mbzH3EZ/2brd63G/LICx+8a64Ge+C1MaM\nLQ==\n-----END CERTIFICATE-----\n"
         }
        }
       },
       "sni": "secondary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
      },
      "outlier_detection": {},
      "common_lb_config": {
       "healthy_panic_threshold": {}
      },
      "alt_stat_name": "secondary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
     },
     "last_updated": "2020-04-12T18:22:02.432Z"
    },
    {
     "version_info": "00000001",
     "cluster": {
      "@type": "type.googleapis.com/envoy.api.v2.Cluster",
      "name": "v1.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
      "type": "EDS",
      "eds_cluster_config": {
       "eds_config": {
        "ads": {}
       }
      },
      "connect_timeout": "5s",
      "circuit_breakers": {},
      "tls_context": {
       "common_tls_context": {
        "tls_params": {},
        "tls_certificates": [
         {
          "certificate_chain": {
           "inline_string": "-----BEGIN CERTIFICATE-----\nMIICSTCCAe+gAwIBAgIBCjAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDUzN1oX\nDTIwMDQxNTE4MDUzN1owLTErMCkGA1UEAxMiY2xpZW50LnN2Yy5kZWZhdWx0LjFk\nYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABMvzbDE7CXj7\n+DfyI9/WWPXNzYrTalKIVGz1+Ebql52sWe6gVpsQTEoxtM/88td4os1/IxnC7nG/\nW2lV+Lgn3d6jgfwwgfkwDgYDVR0PAQH/BAQDAgO4MB0GA1UdJQQWMBQGCCsGAQUF\nBwMCBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMCkGA1UdDgQiBCDoaeWonBuaDAHv\nMUJ1b2EB83boUURfpQ0/yVTdBlqtDDArBgNVHSMEJDAigCBfHndAYlFpB46JHbcU\nByOHUZEShYhvl+x/x2VR708e+DBiBgNVHREEWzBZhldzcGlmZmU6Ly8xZGI1NGY2\nZi05ZmEwLTVjNWQtNWNmZS1iYzBiOWU2ZGJkNjIuY29uc3VsL25zL2RlZmF1bHQv\nZGMvZW52b3ktbGFiL3N2Yy9jbGllbnQwCgYIKoZIzj0EAwIDSAAwRQIhALq0PokS\nRcjCSGWXVzAjTVPOB3J0wZqJk6HZe/Iyfm3PAiBlxJ5GJFm3emtVzUT+iM39rIET\nDoG/2Uz2st7NrAO8xw==\n-----END CERTIFICATE-----\n"
          },
          "private_key": {
           "inline_string": "[redacted]"
          }
         }
        ],
        "validation_context": {
         "trusted_ca": {
          "inline_string": "-----BEGIN CERTIFICATE-----\nMIICDTCCAbOgAwIBAgIBCDAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDYzNloX\nDTMwMDQxMjE4MDYzNlowMDEuMCwGA1UEAxMlcHJpLWx5N2lxMG0uY29uc3VsLmNh\nLjFkYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAAuUem3\nztCG2lzgB5DOvxDGfuSM+YJ1e3Hed3EWHE6PYlT7TXi9xgGTW2/yKacuYCR3zD8F\no39cqb2siIqYBs+jgb0wgbowDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMB\nAf8wKQYDVR0OBCIEIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MCsG\nA1UdIwQkMCKAIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MD8GA1Ud\nEQQ4MDaGNHNwaWZmZTovLzFkYjU0ZjZmLTlmYTAtNWM1ZC01Y2ZlLWJjMGI5ZTZk\nYmQ2Mi5jb25zdWwwCgYIKoZIzj0EAwIDSAAwRQIgBacTc/BgC+7CkzQWR36uxsQj\nHVxruXfaovikz6pCFegCIQCvufZqQK/mbzH3EZ/2brd63G/LICx+8a64Ge+C1MaM\nLQ==\n-----END CERTIFICATE-----\n"
         }
        }
       },
       "sni": "v1.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
      },
      "outlier_detection": {},
      "common_lb_config": {
       "healthy_panic_threshold": {}
      },
      "alt_stat_name": "v1.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
     },
     "last_updated": "2020-04-12T18:22:02.421Z"
    },
    {
     "version_info": "00000001",
     "cluster": {
      "@type": "type.googleapis.com/envoy.api.v2.Cluster",
      "name": "v2.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
      "type": "EDS",
      "eds_cluster_config": {
       "eds_config": {
        "ads": {}
       }
      },
      "connect_timeout": "5s",
      "circuit_breakers": {},
      "tls_context": {
       "common_tls_context": {
        "tls_params": {},
        "tls_certificates": [
         {
          "certificate_chain": {
           "inline_string": "-----BEGIN CERTIFICATE-----\nMIICSTCCAe+gAwIBAgIBCjAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDUzN1oX\nDTIwMDQxNTE4MDUzN1owLTErMCkGA1UEAxMiY2xpZW50LnN2Yy5kZWZhdWx0LjFk\nYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABMvzbDE7CXj7\n+DfyI9/WWPXNzYrTalKIVGz1+Ebql52sWe6gVpsQTEoxtM/88td4os1/IxnC7nG/\nW2lV+Lgn3d6jgfwwgfkwDgYDVR0PAQH/BAQDAgO4MB0GA1UdJQQWMBQGCCsGAQUF\nBwMCBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMCkGA1UdDgQiBCDoaeWonBuaDAHv\nMUJ1b2EB83boUURfpQ0/yVTdBlqtDDArBgNVHSMEJDAigCBfHndAYlFpB46JHbcU\nByOHUZEShYhvl+x/x2VR708e+DBiBgNVHREEWzBZhldzcGlmZmU6Ly8xZGI1NGY2\nZi05ZmEwLTVjNWQtNWNmZS1iYzBiOWU2ZGJkNjIuY29uc3VsL25zL2RlZmF1bHQv\nZGMvZW52b3ktbGFiL3N2Yy9jbGllbnQwCgYIKoZIzj0EAwIDSAAwRQIhALq0PokS\nRcjCSGWXVzAjTVPOB3J0wZqJk6HZe/Iyfm3PAiBlxJ5GJFm3emtVzUT+iM39rIET\nDoG/2Uz2st7NrAO8xw==\n-----END CERTIFICATE-----\n"
          },
          "private_key": {
           "inline_string": "[redacted]"
          }
         }
        ],
        "validation_context": {
         "trusted_ca": {
          "inline_string": "-----BEGIN CERTIFICATE-----\nMIICDTCCAbOgAwIBAgIBCDAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDYzNloX\nDTMwMDQxMjE4MDYzNlowMDEuMCwGA1UEAxMlcHJpLWx5N2lxMG0uY29uc3VsLmNh\nLjFkYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAAuUem3\nztCG2lzgB5DOvxDGfuSM+YJ1e3Hed3EWHE6PYlT7TXi9xgGTW2/yKacuYCR3zD8F\no39cqb2siIqYBs+jgb0wgbowDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMB\nAf8wKQYDVR0OBCIEIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MCsG\nA1UdIwQkMCKAIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MD8GA1Ud\nEQQ4MDaGNHNwaWZmZTovLzFkYjU0ZjZmLTlmYTAtNWM1ZC01Y2ZlLWJjMGI5ZTZk\nYmQ2Mi5jb25zdWwwCgYIKoZIzj0EAwIDSAAwRQIgBacTc/BgC+7CkzQWR36uxsQj\nHVxruXfaovikz6pCFegCIQCvufZqQK/mbzH3EZ/2brd63G/LICx+8a64Ge+C1MaM\nLQ==\n-----END CERTIFICATE-----\n"
         }
        }
       },
       "sni": "v2.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
      },
      "outlier_detection": {},
      "common_lb_config": {
       "healthy_panic_threshold": {}
      },
      "alt_stat_name": "v2.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
     },
     "last_updated": "2020-04-12T18:22:02.409Z"
    }
   ]
  },
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ListenersConfigDump",
   "version_info": "00000001",
   "dynamic_listeners": [
    {
     "name": "public_listener:0.0.0.0:21000",
     "active_state": {
      "version_info": "00000001",
      "listener": {
       "@type": "type.googleapis.com/envoy.api.v2.Listener",
       "name": "public_listener:0.0.0.0:21000",
       "address": {
        "socket_address": {
         "address": "0.0.0.0",
         "port_value": 21000
        }
       },
       "filter_chains": [
        {
         "tls_context": {
          "common_tls_context": {
           "tls_params": {},
           "tls_certificates": [
            {
             "certificate_chain": {
              "inline_string": "-----BEGIN CERTIFICATE-----\nMIICSTCCAe+gAwIBAgIBCjAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDUzN1oX\nDTIwMDQxNTE4MDUzN1owLTErMCkGA1UEAxMiY2xpZW50LnN2Yy5kZWZhdWx0LjFk\nYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABMvzbDE7CXj7\n+DfyI9/WWPXNzYrTalKIVGz1+Ebql52sWe6gVpsQTEoxtM/88td4os1/IxnC7nG/\nW2lV+Lgn3d6jgfwwgfkwDgYDVR0PAQH/BAQDAgO4MB0GA1UdJQQWMBQGCCsGAQUF\nBwMCBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMCkGA1UdDgQiBCDoaeWonBuaDAHv\nMUJ1b2EB83boUURfpQ0/yVTdBlqtDDArBgNVHSMEJDAigCBfHndAYlFpB46JHbcU\nByOHUZEShYhvl+x/x2VR708e+DBiBgNVHREEWzBZhldzcGlmZmU6Ly8xZGI1NGY2\nZi05ZmEwLTVjNWQtNWNmZS1iYzBiOWU2ZGJkNjIuY29uc3VsL25zL2RlZmF1bHQv\nZGMvZW52b3ktbGFiL3N2Yy9jbGllbnQwCgYIKoZIzj0EAwIDSAAwRQIhALq0PokS\nRcjCSGWXVzAjTVPOB3J0wZqJk6HZe/Iyfm3PAiBlxJ5GJFm3emtVzUT+iM39rIET\nDoG/2Uz2st7NrAO8xw==\n-----END CERTIFICATE-----\n"
             },
             "private_key": {
              "inline_string": "[redacted]"
             }
            }
           ],
           "validation_context": {
            "trusted_ca": {
             "inline_string": "-----BEGIN CERTIFICATE-----\nMIICDTCCAbOgAwIBAgIBCDAKBggqhkjOPQQDAjAwMS4wLAYDVQQDEyVwcmktbHk3\naXEwbS5jb25zdWwuY2EuMWRiNTRmNmYuY29uc3VsMB4XDTIwMDQxMjE4MDYzNloX\nDTMwMDQxMjE4MDYzNlowMDEuMCwGA1UEAxMlcHJpLWx5N2lxMG0uY29uc3VsLmNh\nLjFkYjU0ZjZmLmNvbnN1bDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAAuUem3\nztCG2lzgB5DOvxDGfuSM+YJ1e3Hed3EWHE6PYlT7TXi9xgGTW2/yKacuYCR3zD8F\no39cqb2siIqYBs+jgb0wgbowDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMB\nAf8wKQYDVR0OBCIEIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MCsG\nA1UdIwQkMCKAIF8ed0BiUWkHjokdtxQHI4dRkRKFiG+X7H/HZVHvTx74MD8GA1Ud\nEQQ4MDaGNHNwaWZmZTovLzFkYjU0ZjZmLTlmYTAtNWM1ZC01Y2ZlLWJjMGI5ZTZk\nYmQ2Mi5jb25zdWwwCgYIKoZIzj0EAwIDSAAwRQIgBacTc/BgC+7CkzQWR36uxsQj\nHVxruXfaovikz6pCFegCIQCvufZqQK/mbzH3EZ/2brd63G/LICx+8a64Ge+C1MaM\nLQ==\n-----END CERTIFICATE-----\n"
            }
           }
          },
          "require_client_certificate": true
         },
         "filters": [
          {
           "name": "envoy.ext_authz",
           "config": {
            "stat_prefix": "connect_authz",
            "grpc_service": {
             "initial_metadata": [
              {
               "key": "x-consul-token"
              }
             ],
             "envoy_grpc": {
              "cluster_name": "local_agent"
             }
            }
           }
          },
          {
           "name": "envoy.tcp_proxy",
           "config": {
            "stat_prefix": "public_listener_tcp",
            "cluster": "local_app"
           }
          }
         ]
        }
       ]
      },
      "last_updated": "2020-04-12T18:22:02.438Z"
     }
    },
    {
     "name": "nginx:127.0.0.1:19191",
     "active_state": {
      "version_info": "00000001",
      "listener": {
       "@type": "type.googleapis.com/envoy.api.v2.Listener",
       "name": "nginx:127.0.0.1:19191",
       "address": {
        "socket_address": {
         "address": "127.0.0.1",
         "port_value": 19191
        }
       },
       "filter_chains": [
        {
         "filters": [
          {
           "name": "envoy.http_connection_manager",
           "config": {
            "http_filters": [
             {
              "name": "envoy.router"
             }
            ],
            "rds": {
             "config_source": {
              "ads": {}
             },
             "route_config_name": "nginx"
            },
            "stat_prefix": "upstream_nginx_http",
            "tracing": {
             "operation_name": "EGRESS",
             "random_sampling": {}
            }
           }
          }
         ]
        }
       ]
      },
      "last_updated": "2020-04-12T18:22:02.440Z"
     }
    }
   ]
  },
  {
   "@type": "type.googleapis.com/envoy.admin.v3.ScopedRoutesConfigDump"
  },
  {
   "@type": "type.googleapis.com/envoy.admin.v3.RoutesConfigDump",
   "dynamic_route_configs": [
    {
     "version_info": "00000004",
     "route_config": {
      "@type": "type.googleapis.com/envoy.api.v2.RouteConfiguration",
      "name": "nginx",
      "virtual_hosts": [
       {
        "name": "nginx",
        "domains": [
         "*"
        ],
        "routes": [
         {
          "match": {
           "prefix": "/secondary"
          },
          "route": {
           "cluster": "secondary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
           "prefix_rewrite": "/"
          }
         },
         {
          "match": {
           "prefix": "/",
           "headers": [
            {
             "name": "x-service-version",
             "exact_match": "v1"
            }
           ]
          },
          "route": {
           "cluster": "primary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
          }
         },
         {
          "match": {
           "prefix": "/",
           "headers": [
            {
             "name": "x-service-version",
             "exact_match": "v2"
            }
           ]
          },
          "route": {
           "cluster": "v2.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul"
          }
         },
         {
          "match": {
           "prefix": "/"
          },
          "route": {
           "weighted_clusters": {
            "clusters": [
             {
              "name": "v1.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
              "weight": 1000
             },
             {
              "name": "v2.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
              "weight": 1000
             },
             {
              "name": "primary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
              "weight": 1000
             },
             {
              "name": "secondary.nginx.default.envoy-lab.internal.1db54f6f-9fa0-5c5d-5cfe-bc0b9e6dbd62.consul",
              "weight": 7000
             }
            ],
            "total_weight": 10000
           }
          }
         }
        ]
       }
      ],
      "validate_clusters": true
     },
     "last_updated": "2020-04-12T18:25:36.835Z"
    }
   ]
  },
  {
   "@type": "type.googleapis.com/envoy.admin.v3.SecretsConfigDump"
  }
 ]
}
```
