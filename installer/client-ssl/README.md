# client-ssl

Builds a self-extracting installer that provisions the **client-side TLS
credentials and kubeconfigs** a worker node needs to join the cluster
(`kubelet` and `kube-proxy`).

The bundle is generated on the build host from the project CA, then copied to a
worker node and executed there. On the node it mints a per-node kubelet client
certificate and writes the kubeconfig files into the locations the kubelet and
kube-proxy services expect.

## Contents

| File                  | Role                                                                       |
| --------------------- | -------------------------------------------------------------------------- |
| `Makefile`            | Collects CA material and packages the self-extracting installer.           |
| `selfinstall`         | Bootstrap header prepended to the tarball; extracts and runs `installer`.  |
| `installer`           | Runs on the target node: generates certs/kubeconfigs and installs them.    |
| `ca.conf`             | OpenSSL config with per-component CSR sections (nodes, kube-proxy, etc.).  |
| `ca.crt` / `ca.key`   | Cluster CA certificate and private key used to sign node certificates.     |
| `ca.srl`              | CA serial file used when signing certificates.                             |
| `client-sslinstaller` | Build output: the runnable self-extracting installer.                      |

## Build

```sh
make            # produces ./client-sslinstaller
make clean      # removes build artifacts and copied CA/config files
```

The build:

1. Copies the CA material (`ca.crt`, `ca.key`, `ca.srl`) from `../../ssl` and
   `ca.conf` from `../../etc/cfg` into this directory.
2. Renders `selfinstall` from the shared `../selfinstall` template with
   `PRJ=client-ssl`.
3. Tars `installer`, the CA files, `ca.conf`, and a `version` stamp, then
   concatenates the tarball onto `selfinstall` to form `client-sslinstaller`.

## Run (on the worker node)

Copy `client-sslinstaller` to the node and execute it (typically as root):

```sh
./client-sslinstaller
```

The `selfinstall` header extracts the embedded archive into a temporary
directory and runs `installer`, which:

1. Creates `/var/lib/kubelet/` and `/var/lib/kube-proxy/`.
2. Detects the node name from the host's primary non-loopback IPv4 address
   (first octet), matching a section in `ca.conf`.
3. Generates a kubelet RSA key and CSR, and signs a kubelet client certificate
   with the cluster CA.
4. Installs the kubelet certificate and key:
   - `/var/lib/kubelet/kubelet.crt` (mode 644)
   - `/var/lib/kubelet/kubelet.key` (mode 600)
5. Builds and installs the kubelet kubeconfig at `/var/lib/kubelet/kubeconfig`,
   pointing at `https://server.kubernetes.local:6443` with the CA embedded and
   the user `system:node:<node>`.
6. Builds and installs the kube-proxy kubeconfig at
   `/var/lib/kube-proxy/kubeconfig` for the user `system:kube-proxy`.

## Requirements

- On the build host: `make`, `envsubst`, `tar`, and the CA material under
  `../../ssl`.
- On the target node: `bash`, `openssl`, `kubectl`, `jq`, `ip`, and `awk`.
- The node name derived from the host IP must have a matching CSR section in
  `ca.conf`.
