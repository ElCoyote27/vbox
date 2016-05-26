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
	echo "NO credentials for subscription Manager found in ./.sm_creds!" ; exit 127
fi


# Get the VMs
VBOX_VM_LIST=$(ssh ${VBOX_USER}@${VBOX_HOST} "VBoxManage list vms|awk '{ if ( \$1 ~ /osp-baremetal/) { print \$1 }}'"|xargs)

# Iterate and delete
for myvm in ${VBOX_VM_LIST}
do
	IRONIC_NODE="${myvm}"
	ssh stack@${INSTACK} ". ./stackrc ; \
		ironic node-set-power-state ${IRONIC_NODE} off ; \
		ironic node-delete ${IRONIC_NODE}"
done
