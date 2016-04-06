#mongodb sharding on Kubernetes

This example assumes that you have a Kubernetes cluster installed and running, and that you have installed the kubectl command line tool somewhere in your path. Please see the getting started for installation instructions for your platform.

#how to use

first launch replicationSet
kubectl create -f rs-node1.yaml 
kubectl create -f rs-node2.yaml 
kubectl create -f rs-node3.yaml

second launch config server
kubectl create -f confsvr-node1.yaml
kubectl create -f confsvr-node2.yaml
kubectl create -f confsvr-node3.yaml

third launch mongos
kubectl create -f mongos-node1.yaml
kubectl create -f mongos-node2.yaml
kubectl create -f mongos-node3.yaml


public class HelloWorld {

  /**
  * @param args
    */
    public static void main(String[] args) {
        System.out.println("HelloWorld!");

    }

}
