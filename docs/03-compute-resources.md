# compute resources 

## /etc/hosts - machines database
See [Makefile](../Makefile) target: install-hosts and [installer/config-host](../installer/config-host/README.md).

## configure SSH access

- SSH root access is enabled during OS installation from the ISO images, as configured in the [alemert/iso](https://github.com/alemert/iso/) deployment setup.
- SSH public keys are also installed during the OS/ISO provisioning process, so each machine is preauthorized for key-based access without manual setup.

Next: [certificate-authority](04-certificate-authority.md)
