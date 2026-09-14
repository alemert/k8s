PROJ := ../..

# CA files needed for signing, sourced from $(PROJ)/ssl
CA_FILES  = ca.crt ca.key ca.srl

# admin kubeconfig generated during installation; the CA config is copied in too
SRC = $(CA_FILES) ca.conf

.INTERMEDIATE : arch.tar.gz
.PHONY : all ca clean
.PRECIOUS : $(CA_FILES)

all : admin-sslinstaller

admin-sslinstaller : selfinstall arch.tar.gz
	cat $^ > $@
	chmod 755 $@

selfinstall: ../selfinstall
	PRJ=admin-ssl envsubst '$$PRJ' < $< > $@

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
	date "+admin-installer %Y-%m-%d" > version
	tar czf $@ $^ version
	rm version

clean:
	rm -f admin-sslinstaller arch.tar.gz version $(SRC)
