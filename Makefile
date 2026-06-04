MACHINES = etc/cfg/machines.txt

.PHONY: all help install-hosts deploy-ssl deploy-ssl-client ssl kubeconfig
.PRECIOUS: var/ssl/ca.key var/ssl/%.key

all: install-hosts deploy-ssl deploy-kubeconfig deploy-encryption

help: 
	@ echo "Usage: make [target]"
	@ echo ""
	@ echo "Targets:"
	@ echo "  all           Generate and deploy /etc/hosts and SSL certificates"
	@ echo "  install-hosts Generate and deploy /etc/hosts to all machines"
	@ echo "  deploy-ssl    Generate and deploy SSL certificates to all machines"
	@ echo "  deploy-kubeconfig Deploy kubeconfig files to all machines"
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

ssl-key-targets := $(patsubst %,var/ssl/%.key,$(cert))
.SECONDARY: var/ssl/ca.key $(ssl-key-targets)

ssl: $(patsubst %,var/ssl/%.crt,$(cert))

var/ssl/:
	@ echo "$@ creating directory for SSL certificates"
	@ mkdir -p $@

# ----------------------------------------------------------
# Generate CA key and certificate.
# ----------------------------------------------------------
var/ssl/ca.key: | var/ssl/
	@ echo "$@ generating CA private key"
	@ openssl genrsa -out $@ 4096

var/ssl/ca.crt: var/ssl/ca.key etc/cfg/ca.conf
	@ echo "$@ generating CA certificate"
	@ openssl req -x509 -new -sha512 -noenc \
	    -key $< -days 3653                \
	    -config $(word 2,$^)              \
	    -out $@

# ----------------------------------------------------------
# Generate client key(s) 
# ----------------------------------------------------------
var/ssl/%.key: | var/ssl/
	@ echo "$@ generating client private key"
	@ openssl genrsa -out $@ 4096

# ----------------------------------------------------------
# Generate client certificate request(s) 
# ----------------------------------------------------------
var/ssl/%.csr: var/ssl/%.key etc/cfg/ca.conf
	@ echo "$@ generating client certificate request"
	@ openssl req -new -sha512   \
	    -key $<                \
	    -config $(word 2,$^)   \
	    -section admin         \
	    -out $@

# ----------------------------------------------------------
# Sign client certificate(s) with CA.
# ----------------------------------------------------------
var/ssl/%.crt: var/ssl/%.csr var/ssl/ca.crt var/ssl/ca.key
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

deploy-ssl-node-crt-%: var/ssl/node-%.crt
	scp $< root@node-$*:/var/lib/kubelet/kubelet.crt

deploy-ssl-node-key-%: var/ssl/node-%.key
	scp $< root@node-$*:/var/lib/kubelet/kubelet.key

deploy-ssl-node-ca-%: var/ssl/ca.crt
	scp $< root@node-$*:/var/lib/kubelet/ca.crt 

deploy-ssl-server: $(patsubst %,var/ssl/%.crt,$(cert-server)) $(patsubst %,var/ssl/%.key,$(cert-server)) var/ssl/ca.crt	
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

KUBE_COMPONENTS = kube-proxy kube-controller-manager kube-scheduler

kubeconfig: var/kube/node-0.kubeconfig var/kube/node-1.kubeconfig \
			var/kube/kube-proxy.kubeconfig                   \
			var/kube/kube-controller-manager.kubeconfig      \
			var/kube/kube-scheduler.kubeconfig               \
			var/kube/admin.kubeconfig

var/kube/node-%.kubeconfig: var/ssl/ca.crt var/ssl/node-%.crt var/ssl/node-%.key
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

$(patsubst %,var/kube/%.kubeconfig,$(KUBE_COMPONENTS)): var/kube/%.kubeconfig: var/ssl/ca.crt var/ssl/%.crt var/ssl/%.key
	@ user="system:$*"; \
	@ echo "$@ generating kubeconfig for $*"; \
	  kubectl config set-cluster $(KUBE_CLUSTER_NAME) \
	      --certificate-authority=$< \
	      --embed-certs=true \
	      --server=$(KUBE_API_SERVER) \
	      --kubeconfig=$@; \
	  kubectl config set-credentials $$user \
	      --client-certificate=$(word 2,$^) \
	      --client-key=$(word 3,$^) \
	      --embed-certs=true \
	      --kubeconfig=$@; \
	  kubectl config set-context $(KUBECONFIG_CONTEXT) \
	      --cluster=$(KUBE_CLUSTER_NAME) \
	      --user=$$user \
	      --kubeconfig=$@; \
	  kubectl config use-context $(KUBECONFIG_CONTEXT) \
	      --kubeconfig=$@

var/kube/admin.kubeconfig: var/ssl/ca.crt \
						var/ssl/admin.crt \
						var/ssl/admin.key
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

deploy-kubeconfig: deploy-kubeconfig-worker \
                   deploy-kubeconfig-server

deploy-kubeconfig-worker: deploy-kubeconfig-node-0 deploy-kubeconfig-node-1

deploy-kubeconfig-node-%: var/kube/node-%.kubeconfig var/kube/kube-proxy.kubeconfig
	scp $< root@node-$*:/var/lib/kubelet/kubeconfig 
	scp $(word 2,$^) root@node-$*:/var/lib/kube-proxy/kubeconfig

deploy-kubeconfig-server: var/kube/admin.kubeconfig $(patsubst %,var/kube/%.kubeconfig,$(KUBE_COMPONENTS))
	scp $^ root@server:~/

################################################################################
# data encryption config and key
################################################################################
var/encrypt/encryption-config.yaml: etc/cfg/encryption-config.yaml
	@ echo "$@ generating encryption config"
	@ mkdir -p $(dir $@)
	export ENCRYPTION_KEY=$$(head -c 32 /dev/urandom | base64); \
	envsubst < $< >$@

deploy-encryption: var/encrypt/encryption-config.yaml
	scp $< root@server:~/ 