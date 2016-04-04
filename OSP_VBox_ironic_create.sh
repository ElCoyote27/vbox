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


# Read password:
echo -n "Please enter password for ${VBOX_USER}@${VBOX_HOST}: "
read -s VBOX_USER_PWD
echo "Starting..."

#
for i in $(seq 1 ${cluster_size})
do
	IRONIC_NODE="osp-baremetal-${i}"

	# Create ironic node..
	sudo ssh ${INSTACK} "su - stack -c \" \
		. ./stackrc ; \
		ironic node-create -n ${IRONIC_NODE} \
		-d pxe_ssh \
		-i ssh_address=${VBOX_HOST_IP} \
		-i ssh_username=${VBOX_USER} \
		-i ssh_virt_type=vbox \
		-i ssh_password=\"${VBOX_USER_PWD}\" \
		\""

		##### These do not work yet (20160310)
		##### -i ssh_key_contents=\"${VBOX_USER_KEY}\" \
		##### -i ssh_key_filename=\"${SSH_KEY_FILE}\" \

	# Find the UUID from the ironic node creatd previously
	IRONIC_UUID=$(sudo ssh ${INSTACK} "su - stack -c \" \
		. ./stackrc ; \
		ironic node-show ${IRONIC_NODE}| \
		awk '{ if ( \\\$2 == \\\"uuid\\\" )  { print \\\$4 } }' \
		\"")

	# Find and process MAC address
	tmpMAC=$( (sudo ssh ${VBOX_HOST} "su - ${VBOX_USER} -c \" \
		 VBoxManage showvminfo ${IRONIC_NODE}\" ")|grep NIC.1|sed -e 's/.*MAC: *//' -e 's/,.*//')

	a1=$(echo ${tmpMAC}|cut -c-2)
	a2=$(echo ${tmpMAC}|cut -c3-4)
	a3=$(echo ${tmpMAC}|cut -c5-6)
	a4=$(echo ${tmpMAC}|cut -c7-8)
	a5=$(echo ${tmpMAC}|cut -c9-10)
	a6=$(echo ${tmpMAC}|cut -c11-12)
	IRONIC_MAC="${a1}:${a2}:${a3}:${a4}:${a5}:${a6}"

	# Update the VM's properties
	sudo ssh ${INSTACK} "su - stack -c \" \
		. ./stackrc ; \
		ironic node-update ${IRONIC_UUID} add \
		properties/cpus=${vm_slave_cpu_default} \
		properties/memory_mb=${vm_slave_memory_default} \
		properties/local_gb=62 \
		properties/cpu_arch=x86_64 \
		\""

	case ${IRONIC_NODE} in
		osp-baremetal-[123])
			NODE_PROFILE="control"
			;;
		osp-baremetal-[45678])
			NODE_PROFILE="ceph-storage"
			;;
		osp-baremetal-9|osp-baremetal-10)
			NODE_PROFILE="swift-storage"
			;;
		osp-baremetal-1[123])
			NODE_PROFILE="compute"
			;;
		*)
			NODE_PROFILE=""
			;;
	esac
	
	# Update the VM's properties
	if [ "x${NODE_PROFILE}" != "x" ]; then
		sudo ssh ${INSTACK} "su - stack -c \" \
			. ./stackrc ; \
			ironic node-update ${IRONIC_UUID} add \
			properties/capabilities=profile:${NODE_PROFILE},boot_option:local \
			\""
	fi

	# Create a port for the VM on the ctlplane network (NIC1)
	sudo ssh ${INSTACK} "su - stack -c \" \
		. ./stackrc ; \
		ironic port-create -n ${IRONIC_UUID} -a ${IRONIC_MAC} \
		\""

	# Set the power state to 'on'
	sudo ssh ${INSTACK} "su - stack -c \" \
		. ./stackrc ; \
		ironic node-set-power-state ${IRONIC_NODE} on
		\""

done
