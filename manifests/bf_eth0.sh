#!/bin/bash

# run if eth0 is not managed by NM
# nmcli con add connection.interface-name eth0 type ethernet connection.id eth0

nmcli con mod eth0 ipv4.addresses 10.1.0.2/24
nmcli con mod eth0 ipv4.method manual
nmcli con up eth0
nmcli con show

# run if eth1 is not a bridge port
# nmcli con add type bridge-slave ifname eth1 master br0 connection.id br0-port1


# install openvswitch pkg
dnf install -y \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/$(uname -m)/openvswitch2.13-2.13.0-67.el8fdp.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/$(uname -m)/openvswitch2.13-devel-2.13.0-67.el8fdp.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/67.el8fdp/$(uname -m)/python3-openvswitch2.13-2.13.0-67.el8fdp.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch-selinux-extra-policy/1.0/23.el8fdp/noarch/openvswitch-selinux-extra-policy-1.0-23.el8fdp.noarch.rpm
