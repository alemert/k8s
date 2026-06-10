PROJ := ../..

# certs and keys generated under $(PROJ)/var/ssl
SSL_FILES  = ca.crt ca.key                       \
             kube-api-server.crt kube-api-server.key   \
             service-accounts.crt service-accounts.key

# kubeconfigs generated under $(PROJ)/var/kube
KUBE_FILES = kube-controller-manager.kubeconfig kube-scheduler.kubeconfig

# encryption config generated under $(PROJ)/var/encrypt
ENC_FILES  = encryption-config.yaml

GENERATED  = $(SSL_FILES) $(KUBE_FILES) $(ENC_FILES)

SRC =  kube-apiserver         kube-controller-manager         kube-scheduler          \
       kube-apiserver.service kube-controller-manager.service kube-scheduler.service  \
	   kube-apiserver-to-kubelet.yaml                         kube-scheduler.yaml     \
	   kubectl $(GENERATED)

.INTERMEDIATE : arch.tar.gz $(GENERATED)

all : controlinstaller

controlinstaller : selfinstall arch.tar.gz
	cat $^ > $@
	chmod 755 $@

selfinstall: ../selfinstall
	PRJ=control envsubst '$$PRJ' < $< > $@

# Copy generated artifacts from the project tree into the bundle directory.
$(SSL_FILES): %: $(PROJ)/var/ssl/%
	cp -p $< $@

$(KUBE_FILES): %: $(PROJ)/var/kube/%
	cp -p $< $@

$(ENC_FILES): %: $(PROJ)/var/encrypt/%
	cp -p $< $@

arch.tar.gz : $(SRC) installer
	date "+control %Y-%m-%d" > version
	tar czf $@ $^ version
	rm version

clean:
	rm -f controlinstaller arch.tar.gz version $(GENERATED)
