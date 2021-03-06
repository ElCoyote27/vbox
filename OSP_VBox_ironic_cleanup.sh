#!/bin/bash

#
source ./config.sh
source ./functions/memory.sh
VBOX_CONF=".config"
source ${VBOX_CONF}
VBOX_CREDS=".vbox_creds_$(uname -n)"

# Credentials
if [ -f ${VBOX_CREDS} ]; then
	. ${VBOX_CREDS}
else
	echo "NO credentials for subscription Manager found in ./.vbox_creds_$(uname -n)!" ; exit 127
fi

# Get the IP of the VBOX hypervisor
VBOX_HOST_IP=$(/usr/bin/getent ahosts ${VBOX_HOST}|awk '/STREAM/ { print $1 }')
if [ "x${VBOX_HOST_IP}" = "x" ]; then
	echo "Unable to find IP for ${VBOX_HOST}" ; exit 127
fi
# Get the IP of the Instack VM
INSTACK_HOST_IP=$(/usr/bin/getent ahosts ${INSTACK_HOST}|awk '/STREAM/ { print $1 }')
if [ "x${INSTACK_HOST_IP}" = "x" ]; then
	echo "Unable to find IP for ${INSTACK_HOST}" ; exit 127
fi

# Sanity Check
ssh -q stack@${INSTACK_HOST_IP} test -f stackrc
if [ $? -ne 0 ]; then
	echo "(EE) Stack not installed or no \$HOME/stackrc file found!"
	exit 127
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
