# k8s

## 1. Introduction

This repository contains documentation for setting up a Kubernetes cluster on bare metal, based on [kubernetes the hard way](https://github.com/alemert/kubernetes-the-hard-way/). 

> **Hint:** For building and running the self-extracting cluster installers, see [installer/README.md](installer/README.md).

## 2. Install OS on Bare Metal Machines

Document the operating system installation steps for all target bare metal nodes in this chapter. This corresponds to [k8s the hardway - prereq](https://github.com/alemert/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md).

### 2.1 Create ISO Images
Use the [ISO directory](iso/) to build bootable installer images and write them to USB sticks.
- Insert the prepared USB stick into the target bare metal machine.
- Power on the machine.
- Select the USB device as the boot source.
- Wait for the operating system installation to complete.
- Confirm the machine powers off automatically after installation.

## 3. Download data
This corresponds to the [Kubernetes the Hard Way jump host setup](https://github.com/alemert/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md).

1. [Download binaries](playbook/01-download.sh)

### 3.1 Downloaded files

The download script organizes the extracted binaries by the role of the machine that uses them:

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

The CNI plugins archive is downloaded but is not extracted by the current script.

## 4. Install K8S
This corresponds to the [installer documentation](installer/README.md).

## 5. Compute Resources_
this corresponds to 
- [k8s the hrardway - compute resources](https://github.com/alemert/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md)