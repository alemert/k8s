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
this corresponds to 
- [k8s the hrardway - jumphost](https://github.com/alemert/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md) 
- [download binaries](playbook/01-download.sh)
- [install client](playbook/02-install-client.sh)
