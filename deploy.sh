#!/bin/bash

if [[ ! -n "${KUBECONFIG}" ]]; then
	echo "error: KUBECONFIG must be set or '-k <kubeconfig>' must be given"
	exit 1
fi

# sets network operator deployment unmanaged from clusterversion
oc patch --type=json -p "$(cat manifests/override-cno-control-patch.yaml)" clusterversion version

# overrides network operator deployment image
oc patch -p "$(cat manifests/override-cno-image-patch.yaml)" deploy network-operator -n openshift-network-operator

# overrides ovn-kubernetes image
oc patch -p "$(cat manifests/override-ovn-kubernetes-image-patch.yaml)" deploy network-operator -n openshift-network-operator

# set external-openvswitch label to nodes with bluefield cards
oc label node sriov-worker-1 network.operator.openshift.io/external-openvswitch=true --overwrite

# deploy sriov-network-operator
git clone https://github.com/zshi-redhat/sriov-network-operator.git
cd sriov-network-operator
git checkout bluefield

export SRIOV_NETWORK_OPERATOR_IMAGE=quay.io/zshi/sriov-network-operator:bluefield
make deploy-setup



