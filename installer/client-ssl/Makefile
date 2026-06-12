PROJ := ../..

# CA files needed for signing, sourced from $(PROJ)/ssl
CA_FILES  = ca.crt ca.key ca.srl

# kubeconfigs generated under $(PROJ)/var/kube
KUBE_FILES =

SRC = $(CA_FILES) ca.conf 

.INTERMEDIATE : arch.tar.gz $(KUBE_FILES)
.PHONY : all ca clean
.PRECIOUS : $(CA_FILES)

all : client-sslinstaller

client-sslinstaller : selfinstall arch.tar.gz
	cat $^ > $@
	chmod 755 $@

selfinstall: ../selfinstall
	PRJ=client-ssl envsubst '$$PRJ' < $< > $@

# ------------------------------------------------------------------------------
# CA & SSL files
# ------------------------------------------------------------------------------

# Copy CA files needed for signing into the local directory.
ca : $(CA_FILES) ca.conf

# Copy generated artifacts from the project tree into the bundle directory.
$(CA_FILES): %: $(PROJ)/ssl/%
	cp -p $< $@

ca.conf: %: $(PROJ)/etc/cfg/%
	cp -p $< $@

# Create a tarball for the installer 
arch.tar.gz : $(SRC) installer
	date "+client-installer %Y-%m-%d" > version
	tar czf $@ $^ version
	rm version

clean:
	rm -f client-sslinstaller arch.tar.gz version $(SRC)
