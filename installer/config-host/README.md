# config-host

> **Work in progress:** This installer is still being developed. The current
> implementation assumes that `/etc/hosts` will be managed remotely over SSH.
> That is not the intended design: the installer will be executed locally on
> each host and should update that host's `/etc/hosts` file locally. The
> current remote-deployment logic is therefore temporary and will be replaced.

Builds a self-extracting installer that generates and deploys the cluster
`/etc/hosts` entries to all machines listed in `etc/cfg/machines.txt`.

The bundle is assembled on the build host and executed from a machine that can
SSH to each target node as `root`.

## Contents

| File                  | Role                                                                  |
| --------------------- | --------------------------------------------------------------------- |
| `Makefile`            | Copies the machine list and packages the self-extracting installer.    |
| `selfinstall`         | Bootstrap header that extracts and runs `installer`.                  |
| `installer`            | Generates the hosts file and deploys it to every listed machine.       |
| `machines.txt`         | Build-time copy of `../../etc/cfg/machines.txt`.                      |
| `config-hostinstaller` | Build output: the runnable self-extracting installer.                |

## Build

```sh
make            # produces ./config-hostinstaller
make clean      # removes build artifacts and copied input files
```

The build copies `../../etc/cfg/machines.txt`, renders the shared self-install
header with `PRJ=config-host`, and packages the machine list and runtime
installer into the executable bundle.

## Run

Run the installer from a host with SSH access to every listed node:

```sh
./config-hostinstaller
```

The installer creates entries in this form for each non-comment machine-list
line:

```text
IP FQDN HOST
```

It then appends the generated entries to `/etc/hosts` on every listed machine.
Host-key checking is disabled to match the existing lab deployment behavior.

## Requirements

- On the build host: `make`, `envsubst`, and `tar`.
- On the execution host: `bash`, `ssh`, and root SSH access to every target.
- The machine list must contain `IP FQDN HOST [SUBNET]` fields.
