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

# Create master node for the product
# Get variables "host_nic_name" for the master node
get_instack_name_ifaces

name="${vm_name_prefix}instack"

create_vm $name "${host_nic_name[0]}" $vm_master_cpu_cores $vm_master_memory_mb $vm_master_disk_mb
echo

# Add additional NICs
add_hostonly_adapter_to_vm $name 2 "${host_nic_name[1]}"

add_hostonly_adapter_to_vm $name 3 "${host_nic_name[2]}"

# Add bridged adapter to VM (replaces nic1)
add_bridge_adapter_to_vm $name 4 "${hypervisor_bridged_nic}"

# Add NAT adapter for internet access for all systems
# add_nat_adapter_to_vm $name 5 $vm_master_nat_network


# Mount ISO with installer
# mount_iso_to_vm $name $iso_path

# Start virtual machine with the master node
echo
start_vm $name

# Wait until guestOS is up
sleep 1s
vmaddr=$(VBoxManage showvminfo ${name}|grep NIC.4|sed -e 's/.*MAC: *//' -e 's/,.*//')
if [ "x${vmaddr}" != "x" ]; then
	echo -n "Trying to obtain IP addr for MAC ${vmaddr}..."
	i=1 ; temp_ip=""
	while [ $i -lt 120 ]
	do
		sleep 1s ; echo -n "."
		temp_ip=$(arp -an|sed -e 's/://g'|grep -i ${vmaddr}|sed -e 's/.*(//' -e 's/).*//')
		if [ "x${temp_ip}" != "x" ]; then
			echo "${name} is at IP: ${temp_ip}" | tee -a ${vm_serial_info}
			vm_master_ip="${temp_ip}"
			i=121
		fi
	done
fi

if [ "$skipinstackmenu" = "yes" ]; then
  wait_for_instack_menu $vm_master_ip $vm_master_username $vm_master_password "$vm_master_prompt"
fi

# Wait until the machine gets installed and Puppet completes its run
#wait_for_product_vm_to_install $vm_master_ip $vm_master_username $vm_master_password "$vm_master_prompt"

# Enable outbound network/internet access for the machine
echo enable_outbound_network_for_product_vm $vm_master_ip $vm_master_username $vm_master_password "$vm_master_prompt" 3 $vm_master_nat_gateway
enable_outbound_network_for_product_vm $vm_master_ip $vm_master_username $vm_master_password "$vm_master_prompt" 3 $vm_master_nat_gateway

# Report success
echo
echo "Master node has been installed."

#Sleep 10s to wait for Cobbler to settle
sleep 10
