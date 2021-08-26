# Federated SPIRE

This demo is based on the SPIRE + Envoy tutorial https://github.com/spiffe/spire-tutorials/tree/master/k8s/envoy-x509 and the SPIRE federation tutorial https://github.com/spiffe/spire-tutorials/tree/master/docker-compose/federation.

## Manual setup

### Prerequisites
The prerequisites to deploy the Federated SPIRE demo include
* 2x K8s clusters (Note that sizing of the clusters depends on the workloads. SPIRE only works on single node clusters)
* kubectl CLI and connectivity to both K8s clusters (-> kubeconfig)

### A federated SPIRE architecture setup involves the following generic steps:

**Step 1.** Clone this repository to your user directory so that the following commands are successful
```
$ cd ~/spire-federation-master/participant-a/
$ cd ~/spire-federation-master/participant-b/
```

**Step 2.** Setup Spire Environments  
Open a CLI window and connect to the **Participant-A** cluster and execute
```
$ cd ~/spire-federation-master/
$ kubectl apply -k ./participant-a/
```
Open another CLI window and connect to the **Participant-B** cluster and execute
```
$ cd ~/spire-federation-master/
$ kubectl apply -k ./participant-b/
```

**Step 3.** Check external IP addresses of spire-servers
Execute the following command on both clusters and note the external IP address of the SPIRE server service
```
$ kubectl get services -n spire
```
The output should look like
```
NAME           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
spire-server   ClusterIP   X.X.X.X      **X.X.X.X**   80/TCP    50s
```

**Step 4.** Update the SPIRE server-configmap
Execute the following command in the CLI connected to the **Participant-A** cluster
```
$ cd ~/spire-federation-master/participant-a/
$ vi server-configmap.yaml
```
Go to the line `federates_with "partb.org"` and enter the **IP address of Participant-B SPIRE server service** below in the `address`-attribute and save the file.
```
$ kubectl apply-f server-configmap.yaml
$ kubectl delete pod spire-server-0
```
Execute the following command in the CLI connected to the **Participant-B** cluster
```
$ cd ~/spire-federation-master/participant-b/
$ vi server-configmap.yaml
```
Go to the line `federates_with "parta.org"` and enter the **IP address of Participant-A SPIRE server service** below in the `address`-attribute and save the file.
```
$ kubectl apply-f server-configmap.yaml
$ kubectl delete pod spire-server-0
```
Note that if the standard configuration of the SPIRE service is a nodeport. It may be required to change `server-service.yaml` and change the nodeport to loadbalancer to get a workable external IP address.

**Step 5.** Export each bundle  
Execute the following command in the CLI connected to the **Participant-A** cluster
```
$ kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle show -format spiffe > partA.bundle
```
Execute the following command in the CLI connected to the **Participant-B** cluster
```
$ kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle show -format spiffe > partB.bundle
```

**Step 6.** Copy bundle into spire-server container  
Execute the following command in the CLI connected to the **Participant-A** cluster
```
$ kubectl cp ~/partB.bundle spire/spire-server-0:/
```
Execute the following command in the CLI connected to the **Participant-B** cluster
```
$ kubectl cp ~/partA.bundle spire/spire-server-0:/
```

**Step 7.** Set bundle
Execute the following command in the CLI connected to the **Participant-A** cluster
```
$ ./federate.sh partb.org partB.bundle
```
Execute the following command in the CLI connected to the **Participant-B** cluster
```
$ ./federate.sh parta.org partA.bundle
```

**Step 8.** Check in both clusters if bundle is refreshed and available
```
$ kubectl logs -n spire spire-server-0 | grep '"Bundle refreshed"\|"Bundle set successfully"'
$ kubectl exec -n spire spire-server-0 -- /opt/spire/bin/spire-server bundle list -format spiffe
```

**Step 9.** Create node registration entries for the SPIRE agents
Execute the following command in the CLI connected to the **Participant-A** cluster
```
$ cd participant-a/
$ ./create-node-registration-entry.sh
```
Execute the following command in the CLI connected to the **Participant-B** cluster
```
$ cd participant-b/
$ ./create-node-registration-entry.sh
```

## Playground
In order to test federation and defederation of trust the following can be used for testing.
#### Scripts
```
$ cd ~/spire-federation-master/
$ ls -als
```
The scripts `federate.sh` and `defederate.sh` occur in the output. `$ ./federate.sh $1 $2` with $1 being the trust domain to be federated and $2 being the corresponding trust bundle sets the federation in the SPIRE server of the K8s cluster connected to.
`$ ./defederate.sh $1` with $1 being the trust domain to be defederated removes the trust bundle and federation from the SPIRE server of the K8s cluster connected to. Please note that `defederate.sh` also removes all SPIFFE ID registrations federating with the trust domain being removed.

## Automatic setup (highly dependend on environment)
#### Requirements:
1. You have two running Kubernetes Clusters machines that can reach each other 
1. Install WSL on your Windows PC (https://docs.microsoft.com/de-de/windows/wsl/install-win10)  
1. You have _kubectl_ installed on your WSL (https://kubernetes.io/de/docs/tasks/tools/install-kubectl/)  
1. On your Windows PC: Clone this repository to `C:/` so that it will look like `C:/spire-federated`  

#### Preparation:
1. Load external kubeconfigs into folder `C:/spire-federated/`
    - Typically on k3os the kubeconfig is in `/etc/rancer/k3s/k3s.yaml`
    - Rename kubeconfigs to "kubeconfig-part-a" and "kubeconfig-part-b" (no file ending) 
        * `C:/spire-federated/kubeconfig-part-a`
        * `C:/spire-federated/kubeconfig-part-b`
    - Configure IP-address in kubeconfig from localhost to the serves' IP-addresses  
    
&nbsp;&nbsp;&nbsp;&nbsp; _optional:_  
&nbsp;&nbsp;&nbsp;&nbsp; _- To use the kubeconfigs: add `--kubeconfig-flag` to kubectl command_  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; _ex: `kubectl get ns --kubeconfig=C:/spire-federated/kubeconfig-part-a`_  
&nbsp;&nbsp;&nbsp;&nbsp; _- To delete all existing resources:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; `kubectl delete all --all -n {namespace} --kubeconfig=/<dir-kubeconfig>/<kubeconfig-file-name>`_

#### Auto setup:  
`sudo bash autosetup.sh domain-a ip-a domain-b ip-b`  
Example:  
`sudo bash autosetup.sh participant-a.org 192.168.178.10 participant-b.org 192.168.178.11`  

# Main contributors to this demo
* Dominik Dufner, HPE
* Anne Huesges, HPE
