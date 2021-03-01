#!/bin/bash

export K8S_NODE="worker-h09"
export OVS_LOG_LEVEL="info"

mkdir -p /etc/cni/net.d
mkdir -p /var/run/openvswitch
mkdir -p /var/log/openvswitch
mkdir -p /var/lib/openvswitch/etc
mkdir -p /var/run/secrets/kubernetes.io/serviceaccount

podman run --network host --user 0 --name ovn-ipsec -dit --privileged \
	-v /etc/cni/net.d:/var/run/multus/cni/net.d \
	-v /var/run/openvswitch:/run/openvswitch \
	-v /var/log/openvswitch:/var/log/openvswitch \
	-v /var/lib/openvswitch/etc:/etc/openvswitch \
	-v /var/run/secrets/kubernetes.io/serviceaccount:/var/run/secrets/kubernetes.io/serviceaccount \
	-e K8S_NODE=$K8S_NODE \
	-e OVS_LOG_LEVEL=$OVS_LOG_LEVEL \
	--entrypoint /ipsec_init_entrypoint.sh \
	quay.io/zshi/ovn-daemonset:arm-20210222

podman run --network host --user 0 --name ovn-ipsec -dit --privileged \
	-v /etc/cni/net.d:/var/run/multus/cni/net.d \
	-v /var/run/openvswitch:/run/openvswitch \
	-v /var/log/openvswitch:/var/log/openvswitch \
	-v /var/lib/openvswitch/etc:/etc/openvswitch \
	-v /var/run/secrets/kubernetes.io/serviceaccount:/var/run/secrets/kubernetes.io/serviceaccount \
	-e K8S_NODE=$K8S_NODE \
	-e OVS_LOG_LEVEL=$OVS_LOG_LEVEL \
	--entrypoint /ipsec_entrypoint.sh \
	quay.io/zshi/ovn-daemonset:arm-20210222
