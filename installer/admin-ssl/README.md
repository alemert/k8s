# admin-ssl

Builds a self-extracting installer that provisions the **admin client TLS
credentials and kubeconfig** used by the jumpbox to access the Kubernetes API.

The bundle is generated on the build host from the project CA, then copied to an
admin machine and executed there. It creates a client certificate for the `admin`
user and writes a kubeconfig that targets the local API server endpoint.

## Contents

| File                  | Role                                                                       |
| --------------------- | -------------------------------------------------------------------------- |
| `Makefile`            | Collects CA material and packages the self-extracting installer.           |
| `selfinstall`         | Bootstrap header prepended to the tarball; extracts and runs `installer`. |
| `installer`           | Runs on the target host: generates the admin cert and kubeconfig.         |
| `ca.conf`             | OpenSSL config with per-component CSR sections.                           |
| `ca.crt` / `ca.key`   | Cluster CA certificate and private key used to sign the admin certificate. |
| `ca.srl`              | CA serial file used when signing certificates.                             |
| `admin-sslinstaller`  | Build output: the runnable self-extracting installer.                     |

## Build

```sh
make            # produces ./admin-sslinstaller
make clean      # removes build artifacts and copied CA/config files
```

The build:

1. Copies the CA material (`ca.crt`, `ca.key`, `ca.srl`) from `../../ssl` and
   `ca.conf` from `../../etc/cfg` into this directory.
2. Renders `selfinstall` from the shared `../selfinstall` template with
   `PRJ=admin-ssl`.
3. Tars `installer`, the CA files, `ca.conf`, and a `version` stamp, then
   concatenates the tarball onto `selfinstall` to form `admin-sslinstaller`.

## Run (on the admin host)

Copy `admin-sslinstaller` to the machine that will run the admin kubectl
commands and execute it as root:

```sh
./admin-sslinstaller
```

The installer:

1. Generates a new RSA private key for the `admin` user.
2. Builds a CSR using the CA config section for `admin`.
3. Signs the CSR with the cluster CA to produce `admin.crt`.
4. Installs the files under `/root/.kube/`:
   - `admin.key`
   - `admin.crt`
   - `ca.crt`
   - `config`
5. Writes a kubeconfig that targets `https://127.0.0.1:6443` and uses the
   `admin` client identity.

## Requirements

- On the build host: `make`, `envsubst`, and `tar`.
- On the target host: `bash`, `openssl`, and `kubectl`.
- The admin machine must be able to reach the API server endpoint configured in
  the generated kubeconfig.
