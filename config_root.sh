#!/bin/bash
export MASTER_MEMORY=16384
export MASTER_VCPU=8
export MASTER_DISK=30
export WORKER_MEMORY=16384
export WORKER_VCPU=8
export WORKER_DISK=30
export LANG=en_US.UTF-8
export NUM_MASTERS=3
export NUM_WORKERS=2
export NODES_PLATFORM=libvirt
export INT_IF="ens1f0"
export PRO_IF="eno1"
export CLUSTER_NAME="sriov"
export BASE_DOMAIN="dev.metalkube.org"
export IP_STACK=v4
export NETWORK_TYPE="OVNKubernetes"
export CI_TOKEN="sha256~q_QXmhu6vkXOkHM0Y_NeVCch-kLOQXsNo9v0vV-CQII"
export WORKING_DIR=/home/opt/dev-scripts

