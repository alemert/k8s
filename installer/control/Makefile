SRC =  kube-apiserver         kube-controller-manager         kube-scheduler          \
       kube-apiserver.service kube-controller-manager.service kube-scheduler.service  \
	   kube-apiserver-to-kubelet.yaml                         kube-scheduler.yaml     \
	   kubectl 

.INTERMEDIATE : arch.tar.gz 

all : controlinstaller

controlinstaller : selfinstall arch.tar.gz
	cat $^ > $@
	chmod 755 $@

selfinstall: ../selfinstall
	PRJ=control envsubst '$$PRJ' < $< > $@


arch.tar.gz : $(SRC) installer
	date "+etcdinstaller %Y-%m-%d" > version
	tar czf $@ $^ version
	rm version

clean:
	rm -f controlinstaller arch.tar.gz version
