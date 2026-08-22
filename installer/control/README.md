# control

Builds a self-extracting installer that provisions the Kubernetes
**control plane** on a controller node: the API server, controller manager,
and scheduler, along with their certificates, kubeconfigs, encryption config,
and systemd units.

The bundle is assembled on the build host from artifacts already generated in
the project tree, then copied to a controller node and executed there to
install, enable, and start the control plane services.

## Contents

| File                             | Role                                                                    |
| -------------------------------- | ----------------------------------------------------------------------- |
| `Makefile`                       | Collects generated artifacts and packages the self-extracting installer.|
| `selfinstall`                    | Bootstrap header prepended to the tarball; extracts and runs `installer`.|
| `installer`                      | Runs on the target node: installs binaries, certs, configs, units.      |
| `kube-apiserver`                 | API server binary.                                                      |
| `kube-controller-manager`        | Controller manager binary.                                             |
| `kube-scheduler`                 | Scheduler binary.                                                       |
| `kubectl`                        | CLI binary.                                                            |
| `kube-apiserver.service`         | systemd unit for the API server.                                        |
| `kube-controller-manager.service`| systemd unit for the controller manager.                               |
| `kube-scheduler.service`         | systemd unit for the scheduler.                                         |
| `kube-scheduler.yaml`            | Scheduler component configuration.                                      |
| `kube-apiserver-to-kubelet.yaml` | RBAC manifest granting the API server access to kubelets.              |
| `controlinstaller`               | Build output: the runnable self-extracting installer.                  |

## Build

```sh
make            # produces ./controlinstaller
make clean      # removes build artifacts and copied generated files
```

The build:

1. Copies generated artifacts into this directory:
   - certs/keys from `../../var/ssl` (`ca.crt`, `ca.key`, `kube-api-server.crt/key`,
     `service-accounts.crt/key`)
   - kubeconfigs from `../../var/kube`
     (`kube-controller-manager.kubeconfig`, `kube-scheduler.kubeconfig`)
   - encryption config from `../../var/encrypt` (`encryption-config.yaml`)
2. Renders `selfinstall` from the shared `../selfinstall` template with
   `PRJ=control`.
3. Tars the binaries, units, configs, generated artifacts, and a `version`
   stamp, then concatenates the tarball onto `selfinstall` to form
   `controlinstaller`.

## Run (on the controller node)

Copy `controlinstaller` to the node and execute it (as root):

```sh
./controlinstaller
```

The `selfinstall` header extracts the embedded archive into a temporary
directory and runs `installer`, which:

1. Creates `/etc/kubernetes/config` and `/var/lib/kubernetes`.
2. Installs the binaries into `/usr/local/bin/`
   (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kubectl`).
3. Installs certs, keys, and kubeconfigs into `/var/lib/kubernetes/`:
   - CA (`ca.crt` 644, `ca.key` 600)
   - API server TLS (`kube-api-server.crt` 644, `kube-api-server.key` 600)
   - service account signing pair (`service-accounts.crt` 644, `service-accounts.key` 600)
   - `encryption-config.yaml` (600)
   - `kube-controller-manager.kubeconfig` and `kube-scheduler.kubeconfig` (644)
4. Installs `kube-scheduler.yaml` into `/etc/kubernetes/config/`.
5. Installs the systemd units into `/etc/systemd/system/` and runs
   `systemctl daemon-reload`.
6. Enables and starts `kube-apiserver`, `kube-controller-manager`, and
   `kube-scheduler`.

## Requirements

- On the build host: `make`, `envsubst`, `tar`, and the generated artifacts
  under `../../var/ssl`, `../../var/kube`, and `../../var/encrypt`.
- On the target node: `bash`, `systemd`, and root privileges.

## Notes

- `kube-apiserver-to-kubelet.yaml` is bundled but not applied by `installer`;
  apply it with `kubectl` once the API server is reachable to grant the API
  server permission to talk to kubelets.
