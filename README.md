# k8s

This repository contains documentation for setting up a Kubernetes cluster on bare metal, based on [kubernetes the hard way](https://github.com/alemert/kubernetes-the-hard-way/).

> **Hint:** For building and running the self-extracting cluster installers, see [installer/README.md](installer/README.md).

## Install OS on Bare Metal Machines

Document the operating system installation steps for all target bare metal nodes in this chapter.

### Create ISO Images
Use the ISO submodule to build bootable installer images and write them to USB sticks.
- Insert the prepared USB stick into the target bare metal machine.
- Power on the machine.
- Select the USB device as the boot source.
- Wait for the operating system installation to complete.
- Confirm the machine powers off automatically after installation.