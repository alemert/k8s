# Install kubectl for all users with executable permissions.
sudo install -m 0755 downloads/client/kubectl /usr/local/bin/kubectl

# Confirm that kubectl is installed and report its client version.
sudo /usr/local/bin/kubectl version --client