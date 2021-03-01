#!/bin/bash

set -exuo pipefail

function cleanup()
{
  # In order to maintain traffic flows during container restart, we
  # need to ensure that xfrm state and policies are not flushed.

  # Don't allow ovs monitor to cleanup persistent state
  kill $(cat /var/run/openvswitch/ovs-monitor-ipsec.pid 2>/dev/null) 2>/dev/null || true
  # Don't allow pluto to clear xfrm state and policies on exit
  kill -9 $(cat /var/run/pluto/pluto.pid 2>/devnull) 2>/dev/null || true

  /usr/sbin/ipsec --stopnflog
  exit 0
}
trap cleanup SIGTERM


# Don't start IPsec until ovnkube-node has finished setting up the node
counter=0
until [ -f /etc/cni/net.d/10-ovn-kubernetes.conf ]
do
  ((counter++))
  sleep 1
  if [ $counter -gt 300 ];
  then
          echo "ovnkube-node pod has not started after $counter seconds"
          exit 1
  fi
done
echo "ovnkube-node has configured node."

# After a restart of this container (or on initial startup), we flush xfrm state and policy
# before we start pluto and ovs-monitor-ipsec in order to start in a known good state. This
# will result in a small interruption in traffic until pluto and ovs-monitor-ipsec start again.
ip x s flush
ip x p flush

# Workaround for https://github.com/libreswan/libreswan/issues/373
ulimit -n 1024

/usr/libexec/ipsec/addconn --config /etc/ipsec.conf --checkconfig
# Check kernel modules
/usr/libexec/ipsec/_stackmanager start
# Check nss database status
/usr/sbin/ipsec --checknss
# Start the pluto IKE daemon
/usr/libexec/ipsec/pluto --leak-detective --config /etc/ipsec.conf --logfile /var/log/openvswitch/libreswan.log

# Environment variables are for workaround for https://mail.openvswitch.org/pipermail/ovs-dev/2020-October/375734.html
# We now start ovs-monitor-ipsec which will monitor for changes in the ovs
# tunnelling configuration (for example addition of a node) and configures
# libreswan appropriately.
OVS_LOGDIR=/var/log/openvswitch OVS_RUNDIR=/var/run/openvswitch OVS_PKGDATADIR=/usr/share/openvswitch /usr/share/openvswitch/scripts/ovs-ctl --ike-daemon=libreswan --no-restart-ike-daemon start-ovs-ipsec

sleep infinity
