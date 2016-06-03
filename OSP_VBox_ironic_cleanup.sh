#!/bin/bash

#
source ./config.sh
source ./functions/memory.sh
MYCONF=".config"
source ${MYCONF}

# Credentials
if [ -f .vbox_creds ]; then
	. .vbox_creds
else
	echo "NO credentials for subscription Manager found in ./.vbox_creds!" ; exit 127
fi

# Get the IP of the VBOX hypervisor
VBOX_HOST_IP=$(getent hosts ${VBOX_HOST}|awk '{ print $1 }')
if [ "x${VBOX_HOST_IP}" = "x" ]; then
	echo "Unable to find IP for ${VBOX_HOST}" ; exit 127
fi
# Get the IP of the Instack VM
INSTACK_HOST_IP=$(getent hosts ${INSTACK_HOST}|awk '{ print $1 }')
if [ "x${INSTACK_HOST_IP}" = "x" ]; then
	echo "Unable to find IP for ${INSTACK_HOST}" ; exit 127
fi

# Get the VMs
VBOX_VM_LIST=$(ssh ${VBOX_USER}@${VBOX_HOST_IP} "VBoxManage list vms|awk '{ if ( \$1 ~ /osp-baremetal/) { print \$1 }}'"|xargs)

# Iterate and delete
for myvm in ${VBOX_VM_LIST}
do
	IRONIC_NODE="${myvm}"
	ssh stack@${INSTACK_HOST_IP} ". ./stackrc ; \
		ironic node-set-power-state ${IRONIC_NODE} off ; \
		ironic node-delete ${IRONIC_NODE}"
done
