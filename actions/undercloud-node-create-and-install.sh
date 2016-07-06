#!/bin/bash

#    Copyright 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

#
# This script creates a master node for the product, launches its installation,
# and waits for its completion
#

# Include the handy functions to operate VMs and track ISO installation progress
source ./config.sh
source ./functions/vm.sh
source ./functions/network.sh
source ./functions/product.sh

# Create the serial port and IP info file..
echo "# $(date)" | tee ${vm_serial_info}

# Get the bridged NIC
hypervisor_bridged_nic=$(get_hypervisor_bridged_nic)

# Create master node for the product
# Get variables "host_nic_name" for the master node
get_instack_name_ifaces

name="${vm_name_prefix}instack"

is_vm_present ${name}
if [ $? -eq 0 ]; then
	echo "VM ${name} already present, skipping..."
else
	create_vm ${name} "${host_nic_name[0]}" ${vm_master_cpu_cores} ${vm_master_memory_mb} ${vm_master_disk_mb}
	echo

	# Change first NIC back to intel (undercloud will not PXE, unlike the baremetal VMs)
	# VBoxManage modifyvm ${name} --nictype1 ${vm_boot_nic_type}

	# Add additional NICs
	add_hostonly_adapter_to_vm ${name} 2 "${host_nic_name[1]}" ${vm_default_nic_type}

	add_hostonly_adapter_to_vm ${name} 3 "${host_nic_name[2]}" ${vm_default_nic_type}

	# Add bridged adapter to VM (replaces nic4)
	add_bridge_adapter_to_vm ${name} 4 "${hypervisor_bridged_nic}" ${vm_default_nic_type}

	# Add NAT adapter for internet access for all systems
	# add_nat_adapter_to_vm $name 5 $vm_master_nat_network

	# Mount ISO with installer
	# mount_iso_to_vm $name $iso_path
fi

# Start virtual machine with the master node
echo
start_vm ${name}

# time to wait for the VM to show up on the network
wait_time=120

# Wait until guestOS is up
sleep 1s
vmaddr=$(VBoxManage showvminfo ${name}|grep NIC.4|sed -e 's/.*MAC: *//' -e 's/,.*//')
if [ "x${vmaddr}" != "x" ]; then
	echo -n "Trying to obtain IP addr for MAC ${vmaddr}..."
	i=1 ; temp_ip=""
	while [ ${i} -lt ${wait_time} ]
	do
		vmbcast=$(/sbin/ip -4 -o a l dev ${hypervisor_bridged_nic} |awk '{ if (( $3 == "inet") && ( $5 == "brd")) { print $6 } }')
		/bin/ping -q -c1 -b ${vmbcast} > /dev/null 2>&1
		sleep 1s
		echo -n "."
		i=$((i+1))
		if [ ${i} -eq ${wait_time} ]; then
			echo "Timeout finding IP for ${name}!"
		fi
		temp_ip=$(/sbin/arp -an|sed -e 's/://g'|grep -i ${vmaddr}|sed -e 's/.*(//' -e 's/).*//'|sort -un)
		if [ "x${temp_ip}" != "x" ]; then
			echo "${name} is at IP: ${temp_ip}" | tee -a ${vm_serial_info}
			vm_master_ip="${temp_ip}"
			if [ -f ./.vbox_creds ]; then
				perl -pi -e "s/INSTACK_HOST=.*/INSTACK_HOST=${vm_master_ip}/g" ./.vbox_creds
			fi
			i=121
		fi
	done
fi

if [ "${skipinstackmenu}" = "yes" ]; then
	wait_for_instack_menu ${vm_master_ip} ${vm_master_username} ${vm_master_password} "${vm_master_prompt}"
fi

# Wait until the machine gets installed and Puppet completes its run
#wait_for_product_vm_to_install $vm_master_ip $vm_master_username $vm_master_password "$vm_master_prompt"

# Enable outbound network/internet access for the machine
enable_outbound_network_for_product_vm ${vm_master_ip} ${vm_master_username} ${vm_master_password} "${vm_master_prompt}" 3 ${vm_master_nat_gateway}

# Report success
echo
echo "Master node has been installed."

#Sleep 5s to wait for VM to settle
sleep 5
