SRC = etcdctl etcd etcd.service

.INTERMEDIATE : arch.tar.gz 

all : etcdinstaller

etcdinstaller : selfinstall arch.tar.gz
	cat $^ > $@
	chmod 755 $@

arch.tar.gz : $(SRC) installer
	date "+etcdinstaller %Y-%m-%d" > version
	tar czf $@ $^ version
	rm version

clean:
	rm -f etcdinstaller arch.tar.gz version