#
# This is the OpenShift ovn overlay network image.
# it provides an overlay network using ovs/ovn/ovn-kube
#
# The standard name for this image is ovn-kube

# Notes:
# This is for a development build where the ovn-kubernetes utilities
# are built in this Dockerfile and included in the image (instead of the rpm)
#
# This is based on centos:7
# openvswitch rpms are from
# http://cbs.centos.org/kojifiles/packages/openvswitch/2.9.0/4.el7/x86_64/
#
# So this file will change over time.

FROM registry.access.redhat.com/ubi8/ubi AS builder

USER root

ENV PYTHONDONTWRITEBYTECODE yes

COPY kubernetes.repo /etc/yum.repos.d/kubernetes.repo
RUN INSTALL_PKGS=" \
	python3-yaml \
	bind-utils \
	procps-ng \
	openssl \
	http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/numactl/2.0.12/11.el8/$(uname -m)/numactl-2.0.12-11.el8.$(uname -m).rpm \
	http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/numactl/2.0.12/11.el8/$(uname -m)/numactl-libs-2.0.12-11.el8.$(uname -m).rpm \
	http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/firewalld/0.8.2/3.el8/noarch/firewalld-filesystem-0.8.2-3.el8.noarch.rpm \
	libpcap \
	kubectl \
	iproute \
	iputils \
	http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/strace/5.7/2.el8/$(uname -m)/strace-5.7-2.el8.$(uname -m).rpm \
	socat \
	unbound-libs \
        " && \
	yum install -y --setopt=tsflags=nodocs --setopt=skip_missing_names_on_install=False $INSTALL_PKGS

RUN yum -y update && yum clean all && rm -rf /var/cache/yum/*

# Get a reasonable version of openvswitch (2.9.2 or higher)
# docker build --build-arg rpmArch=ARCH -f Dockerfile.centos -t some_tag .
# where ARCH can be x86_64 (default), aarch64, or ppc64le
RUN dnf install -y \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/79.el8fdp/$(uname -m)/openvswitch2.13-2.13.0-79.el8fdp.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/79.el8fdp/$(uname -m)/openvswitch2.13-devel-2.13.0-79.el8fdp.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/79.el8fdp/$(uname -m)/python3-openvswitch2.13-2.13.0-79.el8fdp.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch2.13/2.13.0/79.el8fdp/$(uname -m)/openvswitch2.13-ipsec-2.13.0-79.el8fdp.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/openvswitch-selinux-extra-policy/1.0/23.el8fdp/noarch/openvswitch-selinux-extra-policy-1.0-23.el8fdp.noarch.rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/21.el8fdn/$(uname -m)/ovn2.13-20.09.0-21.el8fdn.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/21.el8fdn/$(uname -m)/ovn2.13-central-20.09.0-21.el8fdn.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/21.el8fdn/$(uname -m)/ovn2.13-host-20.09.0-21.el8fdn.$(uname -m).rpm \
http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/ovn2.13/20.09.0/21.el8fdn/$(uname -m)/ovn2.13-vtep-20.09.0-21.el8fdn.$(uname -m).rpm
RUN rm -rf /var/cache/yum

RUN mkdir -p /var/run/openvswitch
RUN mkdir -p /var/run/ovn

# Built in ../../go_controller, then the binaries are copied here.
# put things where they are in the rpm
RUN mkdir -p /usr/libexec/cni/
COPY ovnkube ovn-kube-util ovndbchecker /usr/bin/
COPY ovn-k8s-cni-overlay /usr/libexec/cni/ovn-k8s-cni-overlay

# ovnkube.sh is the entry point. This script examines environment
# variables to direct operation and configure ovn
COPY ovnkube.sh /root/
COPY ovndb-raft-functions.sh /root/
# override the rpm's ovn_k8s.conf with this local copy
COPY ovn_k8s.conf /etc/openvswitch/ovn_k8s.conf

# copy git commit number into image
COPY git_info /root

# iptables wrappers
COPY ./iptables-scripts/iptables /usr/sbin/
COPY ./iptables-scripts/iptables-save /usr/sbin/
COPY ./iptables-scripts/iptables-restore /usr/sbin/
COPY ./iptables-scripts/ip6tables /usr/sbin/
COPY ./iptables-scripts/ip6tables-save /usr/sbin/
COPY ./iptables-scripts/ip6tables-restore /usr/sbin/

LABEL io.k8s.display-name="ovn kubernetes" \
      io.k8s.description="This is a component of OpenShift Container Platform that provides an overlay network using ovn." \
      io.openshift.tags="openshift" \
      maintainer="Phil Cameron <pcameron@redhat.com>"

WORKDIR /root
ENTRYPOINT ["/root/ovnkube.sh"]
