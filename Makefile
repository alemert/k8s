MACHINES = etc/machines.txt

.PHONY: all install-hosts

all: install-hosts

etc/hosts: $(MACHINES)
	echo "" > $@
	echo "# Kubernetes The Hard Way" >> $@
	while read IP FQDN HOST SUBNET; do    \
		ENTRY="$${IP} $${FQDN} $${HOST}"; \
		echo $${ENTRY} >> $@; \
	done < $<

install-hosts: etc/hosts
	for IP in $$(awk 'NF && $$1 !~ /^#/{print $$1}' $<); do      \
		ssh root@$$IP 'cat >> /etc/hosts' < $<; \
	done

ssl/ca.key: | ssl/
	openssl genrsa -out $@ 4096

ssl/ca.crt: ssl/ca.key ssl/ca.conf
	openssl req -x509 -new -sha512 -noenc \
	    -key $< -days 3653 \
	    -config $(word 2,$^) \
	    -out $@

ssl/:
	mkdir -p $@