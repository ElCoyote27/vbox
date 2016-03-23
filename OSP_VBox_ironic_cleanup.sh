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


# Get the SSH Key
for i in $(seq 1 ${cluster_size})
do
	IRONIC_NODE="osp-baremetal-${i}"
	sudo ssh  ${INSTACK} "su - stack -c \". ./stackrc ; \
		ironic node-set-power-state ${IRONIC_NODE} off ; \
		ironic node-delete ${IRONIC_NODE}\""
done
