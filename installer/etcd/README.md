# etcd

Builds a self-extracting installer that provisions **etcd**, the key-value
store backing the Kubernetes control plane, on a controller node. It installs
the `etcd` and `etcdctl` binaries and the etcd systemd unit, then enables and
starts the service.

The bundle is assembled on the build host, then copied to a controller node and
executed there.

## Contents

| File            | Role                                                                      |
| --------------- | ------------------------------------------------------------------------- |
| `Makefile`      | Packages the binaries, unit, and installer into a self-extracting bundle. |
| `selfinstall`   | Bootstrap header prepended to the tarball; extracts and runs `installer`. |
| `installer`     | Runs on the target node: installs binaries and the unit, starts the service. |
| `etcd`          | etcd server binary.                                                       |
| `etcdctl`       | etcd command-line client binary.                                          |
| `etcd.service`  | systemd unit that runs the single-node etcd server.                       |
| `etcdinstaller` | Build output: the runnable self-extracting installer.                     |

## Build

```sh
make            # produces ./etcdinstaller
make clean      # removes build artifacts
```

The build:

1. Renders `selfinstall` from the shared `../selfinstall` template with
   `PRJ=etcd`.
2. Tars `etcdctl`, `etcd`, `etcd.service`, `installer`, and a `version` stamp,
   then concatenates the tarball onto `selfinstall` to form `etcdinstaller`.

## Run (on the controller node)

Copy `etcdinstaller` to the node and execute it (as root):

```sh
./etcdinstaller
```

The `selfinstall` header extracts the embedded archive into a temporary
directory and runs `installer`, which:

1. Installs `etcdctl` and `etcd` into `/usr/local/bin/`.
2. Installs `etcd.service` into `/etc/systemd/system/` and runs
   `systemctl daemon-reload`.
3. Enables and starts the `etcd` service.

## Service configuration

`etcd.service` runs a single-node cluster named `controller` with a
`data-dir` of `/var/lib/etcd`:

- peer URL: `http://127.0.0.1:2380`
- client URL: `http://127.0.0.1:2379`
- initial cluster token: `etcd-cluster-0`
- `Restart=on-failure` (5s delay)

## Requirements

- On the build host: `make`, `envsubst`, and `tar`.
- On the target node: `bash`, `systemd`, and root privileges.
