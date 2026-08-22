# installer

Self-extracting installers for bringing up a "Kubernetes The Hard Way"
cluster. Each sub-project builds a single runnable bundle (`selfinstall` header
+ embedded tarball) that is copied to a target machine and executed there to
install binaries, certificates, configs, and systemd units.

## Sub-projects

| # | Project                    | Runs on         | Purpose                                                                 |
| - | -------------------------- | --------------- | ----------------------------------------------------------------------- |
| 1 | [`etcd`](etcd/)            | controller node | Installs the etcd key-value store that backs the control plane.         |
| 2 | [`control`](control/)      | controller node | Installs the control plane: API server, controller manager, scheduler.  |
| 3 | [`client-ssl`](client-ssl/)| worker node     | Generates and installs kubelet/kube-proxy client certs and kubeconfigs. |

Each sub-project has its own `README.md` with details.

## Order of installation

The projects must be installed in this order:

1. **`etcd`** — the datastore must be running before the control plane starts.
2. **`control`** — the API server connects to etcd; install after etcd is up.
3. **`client-ssl`** — worker credentials, installed on each worker node once
   the control plane is reachable.

Steps 1 and 2 target the controller node; step 3 targets each worker node.

## Build

Each sub-project builds independently:

```sh
make -C etcd            # -> etcd/etcdinstaller
make -C control         # -> control/controlinstaller
make -C client-ssl      # -> client-ssl/client-sslinstaller
```

Every `Makefile` renders the shared [`selfinstall`](selfinstall) template with
its own `PRJ` name, then concatenates it with a tarball of the project's
payload to produce the runnable installer.

## Run

Copy the built installer to the appropriate machine and execute it as root, in
the order above. For example:

```sh
scp etcd/etcdinstaller           root@controller:~/  && ssh root@controller ./etcdinstaller
scp control/controlinstaller     root@controller:~/  && ssh root@controller ./controlinstaller
scp client-ssl/client-sslinstaller root@worker:~/    && ssh root@worker ./client-sslinstaller
```

## Shared files

- [`selfinstall`](selfinstall) — the common bootstrap header. It locates the
  `__ARCHIVE__` marker, extracts the embedded tarball to a temp directory, and
  runs the bundled `installer`. Sub-project Makefiles substitute `PRJ` into it.
