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
delegates. To enable this CNI, the Multus conf file (`00-multus.conf`) needs to
modified to point to `infra-dpu-cni` instead of `ovn-k8s-cni-overlay`.

Original Multus conf file:

```
sudo cat /etc/kubernetes/cni/net.d/00-multus.conf
{ "cniVersion": "0.3.1", "name": "multus-cni-network", "type": "multus", "namespaceIsolation": true, "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator", "logLevel": "verbose", "binDir": "/opt/multus/bin", "readinessindicatorfile": "/var/run/multus/cni/net.d/10-ovn-kubernetes.conf", "kubeconfig": "/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig", "delegates": [ {"cniVersion":"0.4.0","name":"ovn-kubernetes","type":"ovn-k8s-cni-overlay","ipam":{},"dns":{},"logFile":"/var/log/ovn-kubernetes/ovn-k8s-cni-overlay.log","logLevel":"4","logfile-maxsize":100,"logfile-maxbackups":5,"logfile-maxage":5} ] }
```

Updated Multus conf file to enable `infra-dpu-cni`:

```
sudo cat /etc/kubernetes/cni/net.d/00-multus.conf
{ "cniVersion": "0.3.1", "name": "multus-cni-network", "type": "multus", "namespaceIsolation": true, "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator", "logLevel": "verbose", "binDir": "/opt/multus/bin", "readinessindicatorfile": "/var/run/multus/cni/net.d/10-infra-dpu-cni.conf", "kubeconfig": "/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig", "delegates": [ {"cniVersion":"0.4.0","name":"infra-dpu-cni","type":"infra-dpu-cni"} ] }
```

## Notes On Multus

There are two fields in `00-multus.conf` that need to be updated:
* `readinessindicatorfile`: This field is the filename of the file created by
  the CNI to indicate it is ready. The value in 00-multus.conf is passed into
  Multus as an input parameter. The `multus-xxxxx` pod is part of a Daemonset
  created by CNO. The `multus.yaml` created by CNO has the value.
* `delegates`: For each CNI, this field contains the CNI Configuration data
  (NetConf data) passed to each CNI call. It is populate from the contents of
  the "readinessindicatorfile".

When Multus pod is started on a given node, it regenerates the `00-multus.conf`
file. So even if the file is modified as above, it will be regenerated on a Multus
restart. Upon regeneration, it sets the `readinessindicatorfile` to the passed
in parameter. Multus then examines the same directory as the `readinessindicatorfile`
(for example: `/etc/kubernetes/cni/net.d/`) for any file (doesn't have to be the
same filename as the `readinessindicatorfile`). If it doesn't find one, it waits
in a loop:


```
# oc logs -n openshift-multus multus-hcjhx
Successfully copied files in /usr/src/multus-cni/rhel8/bin/ to /host/opt/cni/bin/
2021-10-15T18:08:01+00:00 WARN: {unknown parameter "-"}
2021-10-15T18:08:01+00:00 Entrypoint skipped copying Multus binary.
2021-10-15T18:08:01+00:00 Generating Multus configuration file using files in /host/var/run/multus/cni/net.d...
2021-10-15T18:08:01+00:00 Attempting to find master plugin configuration, attempt 0
2021-10-15T18:08:06+00:00 Attempting to find master plugin configuration, attempt 5
2021-10-15T18:08:11+00:00 Attempting to find master plugin configuration, attempt 10
2021-10-15T18:08:16+00:00 Attempting to find master plugin configuration, attempt 15
2021-10-15T18:08:21+00:00 Attempting to find master plugin configuration, attempt 20
:
```

Once it finds a file, it uses the contents to populate the `delegates` field:

```
# oc logs -n openshift-multus multus-hcjhx
:
2021-10-15T16:40:22+00:00 Attempting to find master plugin configuration, attempt 130
2021-10-15T16:40:27+00:00 Attempting to find master plugin configuration, attempt 135
2021-10-15T16:40:32+00:00 Attempting to find master plugin configuration, attempt 140
2021-10-15T16:40:38+00:00 Nested capabilities string: 
2021-10-15T16:40:38+00:00 Using /host/var/run/multus/cni/net.d/10-infra-dpu-cni.conf as a source to generate the Multus configuration
2021-10-15T16:40:38+00:00 Config file created @ /host/etc/cni/net.d/00-multus.conf
{ "cniVersion": "0.3.1", "name": "multus-cni-network", "type": "multus", "namespaceIsolation": true, "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator", "logLevel": "verbose", "binDir": "/opt/multus/bin", "readinessindicatorfile": "/var/run/multus/cni/net.d/10-ovn-kubernetes.conf", "kubeconfig": "/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig", "delegates": [ {"cniVersion":"0.4.0","name":"infra-dpu-cni","type":"infra-dpu-cni"} ] }
2021-10-15T16:40:38+00:00 Entering watch loop...
```

At this point, Multus needs to find the `readinessindicatorfile`. In the logs above.
the `readinessindicatorfile` is `10-ovn-kubernetes.conf` but the file on disk is
`10-infra-dpu-cni.conf`. `00-multus.conf` can be updated to change the
`readinessindicatorfile` to point to `10-infra-dpu-cni.conf`, and it will work
until the Multus pod is restarted.

Two Possible Options:
. Update CNO to add another DaemonSet, `multus-dpu`, which uses a node-selector
  to only run on DPUs. This DaemonSet has a different yaml that passes in a
  different parameter value for `readinessindicatorfile`. The existing `multus`
  DaemonSet would also need to be updated to not run on DPUs.
. Hijack `10-ovn-kubernetes.conf` and change the content from what OVN-Kubernetes
  expect to what `infra-dpu-cni` expects.

The manual steps below are using Option 2. Option 1, or something similar, is the
right way to go and is being explored.

## Manual Installation Steps

To use, copy the script to the directory on each DPU containing the CNI binaries.


From ARM Provisioning Host (where `192.168.123.191` is the IP of the DPU):

```
scp /root/bluefield-demo/infra-dpu-cni/infra-dpu-cni core@192.168.123.191:/var/home/core/.
scp /root/bluefield-demo/infra-dpu-cni/10-ovn-kubernetes.conf core@192.168.123.191:/var/home/core/.
```

On each DPU:

```
sudo mv infra-dpu-cni /var/lib/cni/bin/.
sudo rm /var/run/multus/cni/net.d/*.conf
sudo cp 10-ovn-kubernetes.conf /var/run/multus/cni/net.d/10-ovn-kubernetes.conf
```

On ARM Provisioning Host, safest to restart Multus running on the DPU:

```
# oc get pods -o wide -n openshift-multus | grep bf2-worker
multus-7xhq7                         1/1   Running   45  43d   192.168.123.191  bf2-worker-advnetlab45
multus-additional-cni-plugins-lzkjm  1/1   Running   8   44d   192.168.123.163  bf2-worker-advnetlab46
multus-additional-cni-plugins-wq4sz  1/1   Running   17  43d   192.168.123.191  bf2-worker-advnetlab45
multus-ldsn4                         1/1   Running   0   75m   192.168.123.163  bf2-worker-advnetlab46
network-metrics-daemon-954th         2/2   Running   21  43d   10.132.2.3       bf2-worker-advnetlab45
network-metrics-daemon-qm86n         2/2   Running   12  44d   10.135.0.4       bf2-worker-advnetlab46

# oc delete pod -n openshift-multus multus-7xhq7
# oc delete pod -n openshift-multus multus-ldsn4
```

## Automated Installation

This is still TBD. Some component (Machine Config Operator, Cluster Network Operator,
DPU Operator, Multus Daemonset) will need to perform similar steps.
