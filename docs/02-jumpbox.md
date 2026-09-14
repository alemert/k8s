# jumpbox

This chapter describes how to prepare the jumpbox used to administer the Kubernetes lab.

## install CLI utilities

```bash
  apt-get update
  apt-get -y install wget curl vim openssl git
```

##  dowload binaries

```bash
call playbook/01-download.sh 
```

this will create 
```text
downloads/
|-- client/
|   |-- kubectl
|   `-- etcdctl
|-- controller/
|   |-- etcd
|   |-- kube-apiserver
|   |-- kube-controller-manager
|   `-- kube-scheduler
|-- worker/
|   |-- kubelet
|   |-- kube-proxy
|   |-- crictl
|   |-- runc
|   |-- containerd
|   |-- containerd-shim-runc-v2
|   `-- ctr
`-- cni-plugins-linux-<arch>-v1.6.2.tgz
```

## install k8s client

```bash
call playbook/02-install-client.sh
```

Next: [compute-resources](03-compute-resources.md)

