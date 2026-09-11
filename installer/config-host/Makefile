PROJ := ../..

SRC = machines.txt installer

.INTERMEDIATE : arch.tar.gz
.PHONY : all clean

all : config-hostinstaller

config-hostinstaller : selfinstall arch.tar.gz
	cat $^ > $@
	chmod 755 $@

selfinstall: ../selfinstall
	PRJ=config-host envsubst '$$PRJ' < $< > $@

machines.txt: $(PROJ)/etc/cfg/machines.txt
	cp -p $< $@

arch.tar.gz : $(SRC)
	date "+config-hostinstaller %Y-%m-%d" > version
	tar czf $@ $^ version
	rm version

clean:
	rm -f config-hostinstaller arch.tar.gz version machines.txt selfinstall
