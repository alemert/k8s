MACHINES = etc/machines.txt

.PHONY: all help install-hosts deploy-ssl deploy-ssl-client ssl kubeconfig
.PRECIOUS: ssl/ca.key ssl/%.key

all: install-hosts deploy-ssl 

help: 
	@ echo "Usage: make [target]"
	@ echo ""
	@ echo "Targets:"
	@ echo "  all           Generate and deploy /etc/hosts and SSL certificates"
	@ echo "  install-hosts Generate and deploy /etc/hosts to all machines"
	@ echo "  deploy-ssl    Generate and deploy SSL certificates to all machines"
	@ echo "  help          Display this help message"
	@ echo ""

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

ssl-key-targets := $(patsubst %,ssl/%.key,$(cert))
.SECONDARY: ssl/ca.key $(ssl-key-targets)

ssl: $(patsubst %,ssl/%.crt,$(cert))

ssl/:
	@ echo "$@ creating directory for SSL certificates"
	@ mkdir -p $@

# ----------------------------------------------------------
# Generate CA key and certificate.
# ----------------------------------------------------------
ssl/ca.key: | ssl/
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
ssl/%.csr: ssl/%.key etc/ca.conf
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

deploy-ssl: deploy-ssl-client deploy-ssl-server ssl 

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

################################################################################
# kubeconfig	
################################################################################

KUBE_CLUSTER_NAME = kubernetes-the-hard-way
KUBE_API_SERVER = https://server.kubernetes.local:6443
KUBE_ADMIN_API_SERVER = https://127.0.0.1:6443
KUBECONFIG_CONTEXT = default
KUBE_NODE_USER_PREFIX = system:node
KUBE_PROXY_USER = system:kube-proxy
KUBE_CONTROLLER_MANAGER_USER = system:kube-controller-manager
KUBE_SCHEDULER_USER = system:kube-scheduler
KUBE_ADMIN_USER = admin

kubeconfig: etc/node-0.kubeconfig etc/node-1.kubeconfig        \
			etc/kube-proxy.kubeconfig                          \
						etc/kube-controller-manager.kubeconfig \
						etc/kube-scheduler.kubeconfig          \
						etc/admin.kubeconfig

etc/node-%.kubeconfig: ssl/ca.crt ssl/node-%.crt ssl/node-%.key
	@ host=$(basename $(notdir $(word 2,$^)));           \
	  echo "$@ generating kubeconfig for $$host";        \
	  kubectl config set-cluster $(KUBE_CLUSTER_NAME)    \
	          --certificate-authority=$<                 \
	          --embed-certs=true                         \
	          --server=$(KUBE_API_SERVER)                \
	          --kubeconfig=$@; 
	  kubectl config set-credentials $(KUBE_NODE_USER_PREFIX):$$host \
	          --client-certificate=$(word 2,$^)          \
	          --client-key=$(word 3,$^)                  \
	          --embed-certs=true                         \
	          --kubeconfig=$@
	  kubectl config set-context $(KUBECONFIG_CONTEXT)   \
	              --cluster=$(KUBE_CLUSTER_NAME)         \
	              --user=$(KUBE_NODE_USER_PREFIX):$$host \
	              --kubeconfig=$@

etc/kube-proxy.kubeconfig: ssl/ca.crt                 \
                           ssl/kube-proxy.crt ssl/kube-proxy.key
	@ echo "$@ generating kubeconfig for kube-proxy"
	kubectl config set-cluster $(KUBE_CLUSTER_NAME)   \
	--certificate-authority=$<                        \
	--embed-certs=true                                \
	--server=$(KUBE_API_SERVER)                       \
	--kubeconfig=$@
	kubectl config set-credentials $(KUBE_PROXY_USER) \
    --client-certificate=$(word 2,$^)                 \
    --client-key=$(word 3,$^)                         \
    --embed-certs=true                                \
	    --kubeconfig=$@
	kubectl config set-context $(KUBECONFIG_CONTEXT) \
    --cluster=$(KUBE_CLUSTER_NAME)                   \
    --user=$(KUBE_PROXY_USER)                        \
	    --kubeconfig=$@
	kubectl config use-context $(KUBECONFIG_CONTEXT) \
	    --kubeconfig=$@

etc/kube-controller-manager.kubeconfig: ssl/ca.crt      \
						ssl/kube-controller-manager.crt \
						ssl/kube-controller-manager.key
	@ echo "$@ generating kubeconfig for kube-controller-manager"
	kubectl config set-cluster $(KUBE_CLUSTER_NAME)  \
	    --certificate-authority=$<                   \
	    --embed-certs=true                           \
	    --server=$(KUBE_API_SERVER)                  \
	    --kubeconfig=$@
	kubectl config set-credentials $(KUBE_CONTROLLER_MANAGER_USER) \
	    --client-certificate=$(word 2,$^)            \
	    --client-key=$(word 3,$^)                    \
	    --embed-certs=true                           \
	    --kubeconfig=$@
	kubectl config set-context $(KUBECONFIG_CONTEXT) \
	    --cluster=$(KUBE_CLUSTER_NAME)               \
	    --user=$(KUBE_CONTROLLER_MANAGER_USER)       \
	    --kubeconfig=$@
	kubectl config use-context $(KUBECONFIG_CONTEXT) \
	    --kubeconfig=$@

etc/kube-scheduler.kubeconfig: ssl/ca.crt \
								ssl/kube-scheduler.crt \
								ssl/kube-scheduler.key
	@ echo "$@ generating kubeconfig for kube-scheduler"
	kubectl config set-cluster $(KUBE_CLUSTER_NAME) \
	    --certificate-authority=$<                  \
	    --embed-certs=true                          \
	    --server=$(KUBE_API_SERVER) \
	    --kubeconfig=$@
	kubectl config set-credentials $(KUBE_SCHEDULER_USER) \
	    --client-certificate=$(word 2,$^) \
	    --client-key=$(word 3,$^) \
	    --embed-certs=true    \
	    --kubeconfig=$@
	kubectl config set-context $(KUBECONFIG_CONTEXT) \
	    --cluster=$(KUBE_CLUSTER_NAME) \
	    --user=$(KUBE_SCHEDULER_USER) \
	    --kubeconfig=$@
	kubectl config use-context $(KUBECONFIG_CONTEXT) \
	    --kubeconfig=$@

etc/admin.kubeconfig: ssl/ca.crt \
						ssl/admin.crt \
						ssl/admin.key
	@ echo "$@ generating kubeconfig for admin"
	kubectl config set-cluster $(KUBE_CLUSTER_NAME) \
	    --certificate-authority=$< \
	    --embed-certs=true    \
	    --server=$(KUBE_ADMIN_API_SERVER) \
	    --kubeconfig=$@
	kubectl config set-credentials $(KUBE_ADMIN_USER) \
	    --client-certificate=$(word 2,$^) \
	    --client-key=$(word 3,$^) \
	    --embed-certs=true    \
	    --kubeconfig=$@
	kubectl config set-context $(KUBECONFIG_CONTEXT) \
	    --cluster=$(KUBE_CLUSTER_NAME)    \
	    --user=$(KUBE_ADMIN_USER)       \
	    --kubeconfig=$@
	kubectl config use-context $(KUBECONFIG_CONTEXT) \
	    --kubeconfig=$@

# bis hier; next: distribute kubeconfig files to all machines