SUBDIRS = config-host etcd control client-ssl admin-ssl

.PHONY: all clean $(SUBDIRS)

# Build all installers, in cluster install order.
all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
