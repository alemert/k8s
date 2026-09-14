# certificate authority 

[client-ssl installer](../installer/client-ssl/README.md) handles 

## generate certificates


The certificate lifecycle for this lab is defined in the root [Makefile](../Makefile). The relevant targets generate a local CA, issue client/server certificates, and then copy the resulting artifacts to the machines that need them.

The root Makefile defines the certificate set used by the cluster as three groups, not as a single certificate:

- `cert-admin` = `admin` (1 certificate)
- `cert-client` = `node-0 node-1` (2 certificates)
- `cert-server` = `kube-proxy kube-scheduler kube-controller-manager kube-api-server service-accounts` (5 certificates)

Together, these become:

```make
cert = $(cert-admin) $(cert-client) $(cert-server)
```

So the total is 1 + 2 + 5 = 8 individual component certificates, plus one CA certificate. In GNU Make, each word in `$(cert)` is expanded separately by the pattern rule `var/ssl/%.crt`, so the build creates many certificates, one for each item/word, not just one certificate or three grouped certificates.

The certificate generation flow is built around the following targets and variables:

- `ssl/ca.key` creates the private CA key.
- `ssl/ca.crt` creates the CA certificate using `openssl req -x509` with the CA config from `etc/cfg/ca.conf`.
- `var/ssl/%.key` creates per-component private keys.
- `var/ssl/%.csr` creates certificate signing requests.
- `var/ssl/%.crt` signs each CSR using the root CA and appends the CA serial file.

The Makefile also declares the shared CA configuration used for signing operations:

```bash
ssl/ca.crt: ssl/ca.key etc/cfg/ca.conf
	@ openssl req -x509 -new -sha512 -noenc \
	    -key $< -days 3653 \
	    -config $(word 2,$^) \
	    -out $@
```

The certificate signing itself is performed here:

```bash
var/ssl/%.crt: var/ssl/%.csr ssl/ca.crt ssl/ca.key
	@ openssl x509 -req -days 3653 -sha512 \
		-copy_extensions copyall \
	    -in $< \
	    -CA $(word 2,$^) \
	    -CAkey $(word 3,$^) \
	    -CAcreateserial \
	    -out $@
```

## generate all certificates

Run the certificate generation with:

```bash
make ssl
```

This creates the CA and the per-component certificate files under `ssl/` and `var/ssl/`.

## deploy certificates to machines

The deployment flow is controlled by the `deploy-ssl` target:

```bash
make deploy-ssl
```

This performs two steps:

1. It generates any missing certificate and key files.
2. It copies the generated artifacts to the target hosts using the defined SSH/SCP wrappers.

A subset of the deployment rules copies worker certificates to each node:

```bash
deploy-ssl-node-crt-%: var/ssl/node-%.crt
	$(SCP) $< root@node-$*:/var/lib/kubelet/kubelet.crt
```

The server certificates are bundled and copied to the control-plane host:

```bash
deploy-ssl-server: $(patsubst %,var/ssl/%.crt,$(cert-server)) $(patsubst %,var/ssl/%.key,$(cert-server)) ssl/ca.crt
	$(SCP) $^ root@server:~/
```

In other words, the root Makefile creates the trust anchor and the signed identities required by the Kubernetes control plane and worker nodes, then distributes them to the machines that need them.

## chapter summary

### create the CA

The root CA is created with a private key and a self-signed certificate:

```bash
openssl genrsa -out ssl/ca.key 4096
openssl req -x509 -new -sha512 -noenc \
  -key ssl/ca.key \
  -days 3653 \
  -config etc/cfg/ca.conf \
  -out ssl/ca.crt
```

This creates the trust anchor used to sign all other certificates.

### create a CSR

A CSR is generated from a private key and the CA config for the component name:

```bash
openssl genrsa -out var/ssl/admin.key 4096
openssl req -new -sha512 \
  -key var/ssl/admin.key \
  -config etc/cfg/ca.conf \
  -section admin \
  -out var/ssl/admin.csr
```

### sign the CSR

The CSR is then signed by the CA:

```bash
openssl x509 -req -days 3653 -sha512 \
  -copy_extensions copyall \
  -in var/ssl/admin.csr \
  -CA ssl/ca.crt \
  -CAkey ssl/ca.key \
  -CAcreateserial \
  -out var/ssl/admin.crt
```

This is the same pattern used by the Makefile for every certificate in the cluster.

### how signing creates the key and crt

The CA does not create the final certificate directly from a random file. It signs a CSR that was generated from a component-specific private key.

The sequence is:

1. `openssl genrsa -out var/ssl/admin.key 4096`
   - creates the private key
2. `openssl req -new -sha512 -key var/ssl/admin.key ... -out var/ssl/admin.csr`
   - creates the CSR from that key
3. `openssl x509 -req ... -in var/ssl/admin.csr -CA ssl/ca.crt -CAkey ssl/ca.key -out var/ssl/admin.crt`
   - signs the CSR with the CA and creates the public certificate (`.crt`)

The result is a pair for the component:

- `var/ssl/admin.key` = private key, kept secret on the machine
- `var/ssl/admin.crt` = public certificate, distributed to others

In other words, the CA signs the request, and the signed output is the `.crt`; the private key remains the `.key` that matches it.


