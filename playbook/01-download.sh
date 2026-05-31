ARCH=$(dpkg --print-architecture)
echo "Detected architecture: ${ARCH}"

mkdir -p downloads/{client,cni-plugins,controller,worker}

echo "Downloading k8s binaries "
wget --quiet                       \
     --show-progress               \
     --https-only                  \
     --timestamping                \
	 --directory-prefix=downloads/ \
     --input-file=etc/downloads-amd64.txt

echo "Extracting k8s - cri-o binaries"
tar -xvf downloads/crictl-v1.32.0-linux-${ARCH}.tar.gz \
    -C downloads/worker/

echo "Downloading k8s - containerd binaries "
tar -xvf downloads/containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz \
    --strip-components 1 \
    -C downloads/worker/

echo "Extracting k8s - etcd binaries"
tar -xvf downloads/etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz \
    -C downloads/                                        \
    --strip-components 1                                 \
    etcd-v3.6.0-rc.3-linux-${ARCH}/etcdctl               \
    etcd-v3.6.0-rc.3-linux-${ARCH}/etcd

echo "Reorganizing k8s binaries"
mv downloads/{etcdctl,kubectl} downloads/client/
mv downloads/{etcd,kube-apiserver,kube-controller-manager,kube-scheduler} \
     downloads/controller/
mv downloads/{kubelet,kube-proxy} downloads/worker/
mv downloads/runc.${ARCH} downloads/worker/runc

rm -rf downloads/*.tar.gz