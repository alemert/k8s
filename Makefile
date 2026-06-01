MACHINES = etc/machines.txt

.PHONY: all install-hosts deploy-ssl deploy-ssl-client

all: install-hosts

################################################################################
# generate and deploy /etc/hosts
################################################################################

# ----------------------------------------------------------
# Generate /etc/hosts file from the list of machines. 
# ----------------------------------------------------------
etc/hosts: $(MACHINES)
	echo "" > $@
	echo "# Kubernetes The Hard Way" >> $@
	while read IP FQDN HOST SUBNET; do    \
		ENTRY="$${IP} $${FQDN} $${HOST}"; \
		echo $${ENTRY} >> $@; \
	done < $<

# ----------------------------------------------------------
# Deploy /etc/hosts to all machines.
# ----------------------------------------------------------
install-hosts: etc/hosts
	for IP in $$(awk 'NF && $$1 !~ /^#/{print $$1}' $<); do      \
		ssh root@$$IP 'cat >> /etc/hosts' < $<; \
	done

################################################################################
# Handle SSL certificates
################################################################################
cert-admin = admin
cert-client = node-0 node-1
cert-server = kube-proxy kube-scheduler \
              kube-controller-manager   \
			  kube-api-server

cert = $(cert-admin) $(cert-client) $(cert-server)

ssl: $(patsubst %,ssl/%.crt,$(cert))

ssl/:
	@ echo "$@ creating directory for SSL certificates"
	@ mkdir -p $@

# ----------------------------------------------------------
# Generate CA key and certificate.
# ----------------------------------------------------------
ssl/ca.key: | ssl/#
	@ echo "$@ generating CA private key"
	@ openssl genrsa -out $@ 4096

ssl/ca.crt: ssl/ca.key etc/ca.conf
	@ echo "$@ generating CA certificate"
	@ openssl req -x509 -new -sha512 -noenc \
	    -key $< -days 3653                \
	    -config $(word 2,$^)              \
	    -out $@

# ----------------------------------------------------------
# Generate client key(s) 
# ----------------------------------------------------------
ssl/%.key: | ssl/
	@ echo "$@ generating client private key"
	@ openssl genrsa -out $@ 4096

# ----------------------------------------------------------
# Generate client certificate request(s) 
# ----------------------------------------------------------
ssl/%: ssl/%.key etc/ca.conf
	@ echo "$@ generating client certificate request"
	@ openssl req -new -sha512   \
	    -key $<                \
	    -config $(word 2,$^)   \
	    -section admin         \
	    -out $@

# ----------------------------------------------------------
# Sign client certificate(s) with CA.
# ----------------------------------------------------------
ssl/%.crt: ssl/%.csr ssl/ca.crt ssl/ca.key
	@ echo "$@ signing client certificate with CA"
	@ openssl x509 -req -days 3653 -sha512 \
		-copy_extensions copyall \
	    -in $<                   \
	    -CA $(word 2,$^)         \
	    -CAkey $(word 3,$^)      \
	    -CAcreateserial          \
	    -out $@

deploy-ssl: deploy-ssl-client deploy-ssl-server

deploy-ssl-client: deploy-ssl-node-crt-0 deploy-ssl-node-crt-1 \
                   deploy-ssl-node-key-0 deploy-ssl-node-key-1 

deploy-ssl-node-%: deploy-ssl-node-crt-% deploy-ssl-node-key-% deploy-ssl-node-ca-% 

deploy-ssl-node-crt-%: ssl/node-%.crt
	scp $< root@node-$*:/var/lib/kubelet/kubelet.crt

deploy-ssl-node-key-%: ssl/node-%.key
	scp $< root@node-$*:/var/lib/kubelet/kubelet.key

deploy-ssl-node-ca-%: ssl/ca.crt
	scp $< root@node-$*:/var/lib/kubelet/ca.crt 

deploy-ssl-server: $(patsubst %,ssl/%.crt,$(cert-server)) $(patsubst %,ssl/%.key,$(cert-server)) ssl/ca.crt	
	scp $^ root@server:~/