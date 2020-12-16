#!/bin/bash

export K8S_NODE="worker-h09"
export OVN_LOG_LEVEL="info"

mkdir -p /var/run/ovn
mkdir -p /var/lib/openvswitch/etc
mkdir -p /var/lib/openvswitch/data
mkdir -p /var/run/ovn
mkdir -p /root/ovn-ca
mkdir -p /root/ovn-cert
mkdir -p /root/ovnkube-config

podman run --pid host --network host --user 0 --name ovn-controller -dit --privileged \
	-v /var/run/openvswitch:/run/openvswitch \
	-v /var/run/ovn:/run/ovn \
	-v /var/lib/openvswitch/etc:/etc/openvswitch \
	-v /var/lib/openvswitch/etc:/etc/ovn \
	-v /var/lib/openvswitch/data:/var/lib/openvswitch \
	-v /root/ovnkube-config:/run/ovnkube-config \
	-v /root/ovn-ca:/ovn-ca \
	-v /root/ovn-cert:/ovn-cert \
	-e K8S_NODE=$K8S_NODE \
	-e OVN_LOG_LEVEL=$OVN_LOG_LEVEL \
	--entrypoint=/usr/bin/ovn-controller \
	quay.io/zshi/ovn-daemonset:bluefield-arm-20201214 \
	unix:/var/run/openvswitch/db.sock -vfile:off --no-chdir --pidfile=/var/run/ovn/ovn-controller.pid -p /ovn-cert/tls.key -c /ovn-cert/tls.crt -C /ovn-ca/ca-bundle.crt -vconsole:info
