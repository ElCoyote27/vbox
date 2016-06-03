#!/bin/bash
#
# Requirements: This script must be capable of:
# sudo ssh ${INSTACK_HOST_IP} -l root
#   and:
# sudo ssh ${INSTACK_HOST_IP} -l root "su - stack -c 'ssh ${VBOX_HOST_IP} -l ${VBOX_USER} VBoxManage'"
#

# Initial setup
source ./config.sh
source ./functions/memory.sh
MYCONF=".config"
source ${MYCONF}
IRONIC_KEY="/home/stack/.ssh/ironic_key"

# Credentials
if [ -f .vbox_creds ]; then
	. .vbox_creds
else
	echo "NO credentials for VBOX Manager found in ./.vbox_creds!" ; exit 127
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

# Read the SSH priv key and copy it to the Instack machine..
if [ -f ${VBOX_SSH_KEY_FILE} ]; then
	ssh-copy-id -i ${VBOX_SSH_KEY_FILE} stack@${INSTACK_HOST_IP}
	ssh-copy-id -i ${VBOX_SSH_KEY_FILE} ${VBOX_USER}@${VBOX_HOST_IP}
	scp -p ${VBOX_SSH_KEY_FILE} stack@${INSTACK_HOST_IP}:${IRONIC_KEY}
else
	echo "Unable to locate SSH private key at ${VBOX_SSH_KEY_FILE} on $(uname -n)" ; exit 127
fi

#
for i in $(seq 1 ${cluster_size})
do
	IRONIC_NODE="osp-baremetal-${i}"

	# Create ironic node..
	ssh stack@${INSTACK_HOST_IP} " \
		. ./stackrc ; ironic node-create -n ${IRONIC_NODE} \
		-d pxe_ssh \
		-i ssh_address=${VBOX_HOST_IP} \
		-i ssh_username=${VBOX_USER} \
		-i ssh_virt_type=vbox \
		-i ssh_key_contents=\"\$(cat ${IRONIC_KEY} ) \" "

		##### These do not work yet (20160310)
		##### -i ssh_key_filename=/home/stack/ironic_rsa \
		##### This one works but haem.... YMV (20160310)
		##### -i ssh_password=\"${VBOX_USER_PWD}\" \

	# Find the UUID from the ironic node creatd previously
	IRONIC_UUID=$(ssh stack@${INSTACK_HOST_IP} " \
		. ./stackrc ; \
		ironic node-show ${IRONIC_NODE}| \
		awk '{ if ( \$2 == \"uuid\" )  { print \$4 } }' ")

	# Find and process MAC address
	tmpMAC=$( (ssh ${VBOX_USER}@${VBOX_HOST_IP} " \
		 VBoxManage showvminfo ${IRONIC_NODE}")|grep NIC.1|sed -e 's/.*MAC: *//' -e 's/,.*//')

	a1=$(echo ${tmpMAC}|cut -c-2)
	a2=$(echo ${tmpMAC}|cut -c3-4)
	a3=$(echo ${tmpMAC}|cut -c5-6)
	a4=$(echo ${tmpMAC}|cut -c7-8)
	a5=$(echo ${tmpMAC}|cut -c9-10)
	a6=$(echo ${tmpMAC}|cut -c11-12)
	IRONIC_MAC="${a1}:${a2}:${a3}:${a4}:${a5}:${a6}"

	# Update the VM's properties
	ssh stack@${INSTACK_HOST_IP} " \
		. ./stackrc ; \
		ironic node-update ${IRONIC_UUID} add \
		properties/cpus=${vm_slave_cpu_default} \
		properties/memory_mb=${vm_slave_memory_default} \
		properties/local_gb=62 \
		properties/cpu_arch=x86_64 \
		driver_info/vbox_use_headless=true \
		"

	case ${IRONIC_NODE} in
		osp-baremetal-[123])
			NODE_PROFILE="control"
			;;
		osp-baremetal-[456789])
			NODE_PROFILE="ceph-storage"
			;;
		osp-baremetal-1[012])
			NODE_PROFILE="swift-storage"
			;;
		osp-baremetal-1[345])
			NODE_PROFILE="compute"
			;;
		*)
			NODE_PROFILE="compute"
			;;
	esac
	
	# Update the VM's properties
	if [ "x${NODE_PROFILE}" != "x" ]; then
		ssh stack@${INSTACK_HOST_IP} " \
			. ./stackrc ; \
			ironic node-update ${IRONIC_UUID} add \
			properties/capabilities=profile:${NODE_PROFILE},boot_option:local \
			"
	fi

	# Create a port for the VM on the ctlplane network (NIC1)
	ssh stack@${INSTACK_HOST_IP} " \
		. ./stackrc ; \
		ironic port-create -n ${IRONIC_UUID} -a ${IRONIC_MAC} \
		"

	# Set the power state to 'on'
	ssh stack@${INSTACK_HOST_IP} " \
		. ./stackrc ; \
		ironic node-set-power-state ${IRONIC_NODE} off \
		"

done

# Last steps:

ssh stack@${INSTACK_HOST_IP} ". ./stackrc ; openstack baremetal configure boot ; openstack baremetal show capabilities"

echo "Please remember to: \"openstack baremetal introspection bulk start\" "
