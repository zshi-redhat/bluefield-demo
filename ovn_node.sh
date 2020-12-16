#!/bin/bash

export K8S_NODE="worker-h09"
export OVN_KUBE_LOG_LEVEL=5
export OVN_CONTROLLER_INACTIVITY_PROBE=30000
export KUBERNETES_SERVICE_HOST=api-int.sriov.ovn.testing
export KUBERNETES_SERVICE_PORT=6443
export OVN_GATEWAY_OPTIONS="--gateway-mode local --gateway-interface br-ex"
export OVN_NB_DB_LIST="ssl:192.168.111.20:9641,ssl:192.168.111.21:9641,ssl:192.168.111.22:9641"
export OVN_SB_DB_LIST="ssl:192.168.111.20:9642,ssl:192.168.111.21:9642,ssl:192.168.111.22:9642"
export GENEVE_PORT=6081
export SMART_NIC_IP="192.168.111.55"


mkdir -p /run/ovn-kubernetes
mkdir -p /run/netns
mkdir -p /var/lib/cni/bin
mkdir -p /var/lib/cni/networks

mkdir -p /var/run/secrets/kubernetes.io/serviceaccount
mkdir -p /root/ovn-ca
mkdir -p /root/ovn-cert
mkdir -p /root/ovnkube-node
touch /var/lib/cni/networks/ovn-k8s-cni-overlay

mkdir -p /var/lib/openvswitch/etc
mkdir -p /var/lib/openvswitch/data

podman run --pid host --network host --user 0 --name ovnkube-node -dit --privileged \
	-v /etc/systemd/system:/etc/systemd/system \
	-v /run/ovn-kubernetes:/run/ovn-kubernetes \
	-v /run/netns:/run/netns \
	-v /var/lib/cni/bin:/cni-bin-dir \
	-v /etc/cni/net.d:/var/run/multus/cni/net.d \
	-v /var/run/openvswitch:/run/openvswitch \
	-v /var/lib/cni/networks/ovn-k8s-cni-overlay:/var/lib/cni/networks/ovn-k8s-cni-overlay \
	-v /var/lib/openvswitch/etc:/etc/openvswitch \
	-v /var/lib/openvswitch/etc:/etc/ovn \
	-v /var/lib/openvswitch/data:/var/lib/openvswitch \
	-v /root/ovnkube-config:/run/ovnkube-config \
	-v /root/ovn-ca:/ovn-ca \
	-v /root/ovn-cert:/ovn-cert \
	-v /var/run/ovn:/var/run/ovn \
	-v /var/run/secrets/kubernetes.io/serviceaccount:/var/run/secrets/kubernetes.io/serviceaccount \
	-e K8S_NODE=$K8S_NODE \
	-e OVN_KUBE_LOG_LEVEL=$OVN_KUBE_LOG_LEVEL \
	-e OVN_CONTROLLER_INACTIVITY_PROBE=$OVN_CONTROLLER_INACTIVITY_PROBE \
	-e KUBERNETES_SERVICE_HOST=$KUBERNETES_SERVICE_HOST \
	-e KUBERNETES_SERVICE_PORT=$KUBERNETES_SERVICE_PORT \
	-e OVN_GATEWAY_OPTIONS=$OVN_GATEWAY_OPTIONS \
	-e OVN_NB_DB_LIST=$OVN_NB_DB_LIST \
	-e OVN_SB_DB_LIST=$OVN_SB_DB_LIST \
	--entrypoint /usr/bin/ovnkube \
	quay.io/zshi/ovn-daemonset:bluefield-arm-20201214 \
	--init-node ${K8S_NODE} --encap-ip ${SMART_NIC_IP} --smart-nic --nb-address $OVN_NB_DB_LIST --sb-address $OVN_SB_DB_LIST --nb-client-privkey /ovn-cert/tls.key --nb-client-cert /ovn-cert/tls.crt --nb-client-cacert /ovn-ca/ca-bundle.crt --nb-cert-common-name ovn --sb-client-privkey /ovn-cert/tls.key --sb-client-cert /ovn-cert/tls.crt --sb-client-cacert /ovn-ca/ca-bundle.crt --sb-cert-common-name ovn --config-file=/run/ovnkube-config/ovnkube.conf --loglevel ${OVN_KUBE_LOG_LEVEL}  --inactivity-probe=$OVN_CONTROLLER_INACTIVITY_PROBE $OVN_GATEWAY_OPTIONS --metrics-bind-address 127.0.0.1:29103
