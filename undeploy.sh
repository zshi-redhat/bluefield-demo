#!/bin/bash

cmd=${1:-""}

case ${cmd} in
"image")
	clean_image
	;;
*)
	;;
esac

if [[ ! -n "${KUBECONFIG}" ]]; then
	echo "error: KUBECONFIG must be set or '-k <kubeconfig>' must be given"
	exit 1
fi

ssh_execute() {
	host=$1
	cmd=$2
	ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l core $host "$cmd"
}

clean_image() {
	# remove customized images on nodes (so that they can be reloaded for next testing)
	for i in [10.0.2.10, 10.0.2.11, 10.0.2.12, 10.0.2.13, 10.0.2.14]
	do
		ssh_execute $IP "sudo podman rmi quay.io/zshi/cluster-network-operator:bluefield"
		ssh_execute $IP "sudo podman rmi quay.io/zshi/ovn-daemonset:bluefield"
	done
}

# remove management override for network operator deployment in clusterversion
oc patch --type=json -p "$(cat manifests/remove-cno-control-override.yaml)" clusterversion version

# scale cluster version deployment to 0
oc scale --replicas 0 -n openshift-cluster-version deployments/cluster-version-operator

sleep 5

# scale cluster version deployment to 1
oc scale --replicas 1 -n openshift-cluster-version deployments/cluster-version-operator
