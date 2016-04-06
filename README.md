#mongodb sharding on Kubernetes

This example assumes that you have a Kubernetes cluster installed and running, and that you have installed the kubectl command line tool somewhere in your path. Please see the getting started for installation instructions for your platform.

#how to use

first launch replicationSet
>
kubectl create -f rs-node1.yaml 
>
kubectl create -f rs-node2.yaml 
>
kubectl create -f rs-node3.yaml

second launch config server
>
kubectl create -f confsvr-node1.yaml
>
kubectl create -f confsvr-node2.yaml
>
kubectl create -f confsvr-node3.yaml

third launch mongos
>
kubectl create -f mongos-node1.yaml
>
kubectl create -f mongos-node2.yaml
>
kubectl create -f mongos-node3.yaml

#notice
>
1、replicationSet server port is fixed with 27017，config server is 20000，mongs server is 30000, you can use RS1_SERVICE_PORT change it.
>
2、you can custom replicationSet name just change the variable RepliSetName.
>
3、mongos server must last launch, and you must launch two mongos servers at least.
>
4、when launched then you have to sharding database and set admin password, this just one piece of sharding.
