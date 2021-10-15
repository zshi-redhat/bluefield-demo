#!/bin/bash

if [ ! -z $1 ] ; then
    CONF_FILE=$1
fi

CONF_FILE=${CONF_FILE:-/etc/kubernetes/cni/net.d/00-multus.conf}


if [ ! -f ${CONF_FILE}.bak ] ; then
    echo "Making a backup of original conf file: ${CONF_FILE}.bak"
    cp ${CONF_FILE} ${CONF_FILE}.bak
fi

echo "Updating conf file: ${CONF_FILE}"
sed -i 's@\[.*\]@\[ {"cniVersion":"0.4.0","name":"infra-dpu-cni","type":"infra-dpu-cni"} \]@g' ${CONF_FILE}

