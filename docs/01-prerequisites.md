# Prerequisites

This chapter describes the machines required for the Kubernetes lab and how their operating system is provisioned.

## Virtual or Physical Machines

The lab uses four Ubuntu Server machines. `this-host` is the administration host. `kubi01` is the Kubernetes server host. `kubi02` and `kubi03` are Kubernetes worker hosts.

| Hostname | Role | Description |
| --- | --- | --- |
| `this-host` | Administration host | Runs the administration commands and manages the lab. |
| `kubi01` | Kubernetes server | Control-plane/server host. |
| `kubi02` | Kubernetes worker | Runs workloads scheduled by Kubernetes. |
| `kubi03` | Kubernetes worker | Runs workloads scheduled by Kubernetes. |

The machines may be physical or virtual, but each machine must meet the CPU, memory, storage, and network requirements of the Kubernetes tutorial.

## Operating System

The operating system is provisioned by the ISO configuration in the [alemert/iso](https://github.com/alemert/iso/) repository. Use that repository to build the autoinstall USB and apply the host-specific cloud-init configuration before starting the Kubernetes setup.

The host-specific deployment configuration assigns the following installation targets:

| Hostname | ISO deployment configuration |
| --- | --- |
| `kubi01` | `kubi01` |
| `kubi02` | `kubi02` |
| `kubi03` | `kubi03` |

After installation, verify the operating system on each machine with:

```bash
cat /etc/os-release
```

Also verify the hostname:

```bash
hostnamectl
```

The administration host, `this-host`, is not installed by the `kubi01`, `kubi02`, or `kubi03` deployment configurations. It must already be available as the machine from which the lab commands are run.

Next: [setting-up-the-administration-host](02-jumpbox.md)
