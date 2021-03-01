#!/bin/bash

export K8S_NODE="worker-h09"
export OVS_LOG_LEVEL="info"

# quay.io/zshi/ovn-daemonset:arm-20210222
# build on aarch64, ovn-k8s PR:2005

# quay.io/zshi/ovn-daemonset:arm-20210301
# build on aarch64, ovn-k8s PR:2005, ipsec_* entrypoint script
export OVN_K8S_IMAGE="quay.io/zshi/ovn-daemonset:arm-20210301"

mkdir -p /etc/cni/net.d
mkdir -p /var/run/openvswitch
mkdir -p /var/log/openvswitch
mkdir -p /var/lib/openvswitch/etc
mkdir -p /var/run/secrets/kubernetes.io/serviceaccount
mkdir -p /root/signer-ca
mkdir -p /etc/kubernetes/cni/net.d
touch /etc/kubernetes/cni/net.d/10-ovn-kubernetes.conf

mkdir -p /etc/kubernetes/config/

podman run --network host --user 0 --name ovn-ipsec-init -dit --privileged \
	-v /etc/kubernetes/cni/net.d:/etc/cni/net.d \
	-v /var/run/openvswitch:/run/openvswitch \
	-v /var/log/openvswitch:/var/log/openvswitch \
	-v /var/lib/openvswitch/etc:/etc/openvswitch \
	-v /var/run/secrets/kubernetes.io/serviceaccount:/var/run/secrets/kubernetes.io/serviceaccount \
	-v /root/signer-ca:/signer-ca \
	-v /etc/kubernetes/config:/etc/kubernetes/config \
	-e K8S_NODE=$K8S_NODE \
	-e OVS_LOG_LEVEL=$OVS_LOG_LEVEL \
	--entrypoint /root/ipsec_init_entrypoint.sh \
	$OVN_K8S_IMAGE

podman run --network host --user 0 --name ovn-ipsec -dit --privileged \
	-v /etc/kubernetes/cni/net.d:/etc/cni/net.d \
	-v /var/run/openvswitch:/run/openvswitch \
	-v /var/log/openvswitch:/var/log/openvswitch \
	-v /var/lib/openvswitch/etc:/etc/openvswitch \
	-v /var/run/secrets/kubernetes.io/serviceaccount:/var/run/secrets/kubernetes.io/serviceaccount \
	-v /root/signer-ca:/signer-ca \
	-v /etc/kubernetes/config:/etc/kubernetes/config \
	-e K8S_NODE=$K8S_NODE \
	-e OVS_LOG_LEVEL=$OVS_LOG_LEVEL \
	--entrypoint /root/ipsec_entrypoint.sh \
	$OVN_K8S_IMAGE
