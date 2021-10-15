# Infra Cluster CNI for DPU

This folder contains a script (`infra-dpu-cni`) that performs the actions of a CNI
for the DPU running in the Infra Cluster. OVN-Kubernetes running on the DPU is
performing networking for the Tenant Cluster and is currently not being used for
the Infra Cluster networking. At the moment, non-host networked backed pods are not
supported in the Infra Cluster on the DPU. So this CNI simply returns an error to
all CNI calls.

It is currently assumed that OCP will be installed on the DPUs with OVN-Kubernetes
as the CNI, and after installation, OVN-Kubernetes will be re-deployed to run
in `dpu` mode and this `infra-dpu-cni` will then be installed. By default, Multus is
the default CNI and OVN-Kubernetes will be the only delegate in Multus' list of
delegates. To enable this CNI, the Multus conf file needs to modified to point to
`infra-dpu-cni` instead of `ovn-k8s-cni-overlay`.

Original Multus conf file:

```
sudo cat /etc/kubernetes/cni/net.d/00-multus.conf
{ "cniVersion": "0.3.1", "name": "multus-cni-network", "type": "multus", "namespaceIsolation": true, "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator", "logLevel": "verbose", "binDir": "/opt/multus/bin", "readinessindicatorfile": "/var/run/multus/cni/net.d/10-ovn-kubernetes.conf", "kubeconfig": "/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig", "delegates": [ {"cniVersion":"0.4.0","name":"ovn-kubernetes","type":"ovn-k8s-cni-overlay","ipam":{},"dns":{},"logFile":"/var/log/ovn-kubernetes/ovn-k8s-cni-overlay.log","logLevel":"4","logfile-maxsize":100,"logfile-maxbackups":5,"logfile-maxage":5} ] }
```

Updated Multus conf file to enable `infra-dpu-cni`:

```
sudo cat /etc/kubernetes/cni/net.d/00-multus.conf
{ "cniVersion": "0.3.1", "name": "multus-cni-network", "type": "multus", "namespaceIsolation": true, "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator", "logLevel": "verbose", "binDir": "/opt/multus/bin", "readinessindicatorfile": "/var/run/multus/cni/net.d/10-ovn-kubernetes.conf", "kubeconfig": "/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig", "delegates": [ {"cniVersion":"0.4.0","name":"infra-dpu-cni","type":"infra-dpu-cni"} ] }
```

## Manual Installation Steps

To use, copy the script to the directory on each DPU containing the CNI binaries.


From ARM Provisioning Host (where `192.168.123.191` is the IP of the DPU):
```
scp /root/bluefield-demo/infra-dpu-cni/infra-dpu-cni core@192.168.123.191:/var/home/core/.
scp /root/bluefield-demo/infra-dpu-cni/update-multus-conf.sh core@192.168.123.191:/var/home/core/.
```

On each DPU:
```
sudo mv infra-dpu-cni /var/lib/cni/bin/.
sudo ./update-multus-conf.sh
 Making a backup of original conf file: /etc/kubernetes/cni/net.d/00-multus.conf.bak
 Updating conf file: /etc/kubernetes/cni/net.d/00-multus.conf
```

**NOTE:** The script assumes Multus conf file is
`/etc/kubernetes/cni/net.d/00-multus.conf`. This can be overwritten by passing
in a different file:
```
sudo ./update-multus-conf.sh /local/00-multus.conf
```

## Automated Installation

This is still TBD. Some component (Machine Config Operator, Cluster Network Operator,
DPU Operator, Multus Daemonset) will need to perform similar steps.
