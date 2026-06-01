MACHINES = etc/machines.txt

.PHONY: all install-hosts

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
cert = admin                     \
       node-0 node-1             \
       kube-proxy kube-scheduler \
	   kube-controller-manager   \
	   kube-api-server           \
       service-accounts

ssl: $(patsubst %,ssl/%.crt,$(cert))

ssl/:
	@ echo "Creating directory $@ for SSL certificates"
	@ mkdir -p $@

# ----------------------------------------------------------
# Generate CA key and certificate.
# ----------------------------------------------------------
ssl/ca.key: | ssl/#
	@ echo "Generating CA private key $@"
	@ openssl genrsa -out $@ 4096

ssl/ca.crt: ssl/ca.key etc/ca.conf
	@ echo "Generating CA certificate $@"
	@ openssl req -x509 -new -sha512 -noenc \
	    -key $< -days 3653                \
	    -config $(word 2,$^)              \
	    -out $@

# ----------------------------------------------------------
# Generate client key(s) 
# ----------------------------------------------------------
ssl/%.key: | ssl/
	@ echo "Generating client private key $@"
	@ openssl genrsa -out $@ 4096

# ----------------------------------------------------------
# Generate client certificate request(s) 
# ----------------------------------------------------------
ssl/%: ssl/%.key etc/ca.conf
	@ echo "Generating client certificate request $@"
	@ openssl req -new -sha512   \
	    -key $<                \
	    -config $(word 2,$^)   \
	    -section admin         \
	    -out $@

# ----------------------------------------------------------
# Sign client certificate(s) with CA.
# ----------------------------------------------------------
ssl/%.crt: ssl/%.csr ssl/ca.crt ssl/ca.key
	@ echo "Signing client certificate $@ with CA"
	@ openssl x509 -req -days 3653 -sha512 \
		-copy_extensions copyall \
	    -in $<                   \
	    -CA $(word 2,$^)         \
	    -CAkey $(word 3,$^)      \
	    -CAcreateserial          \
	    -out $@
