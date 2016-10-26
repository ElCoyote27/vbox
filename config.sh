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

source ./functions/memory.sh

# Get the first available ISO from the directory 'iso'
iso_path=`ls -1t iso/*.iso 2>/dev/null | head -1`

# Get the iPXE payload for virtio with bzImage support
rom_path=$(ls -d $(pwd)/rom/*.rom 2>/dev/null | head -1)

# This is the network interface on the host that instack's eth3/bond3 will be bridged too.
# Try every interface in the list in order..
hypervisor_bridged_nic_list="bond0 eth0"

# This file will carry information about the serial ports and instack's IP addres
vm_serial_info="${HOME}/README_vbox_console.txt"

# Every Mirantis OpenStack machine name will start from this prefix
vm_name_prefix=osp-

# NIC types. Boot NIC must be intel or AMD. Other NICs can be virtio
# Types: 82540EM, 82545EM, 82543GC, Am79C973, virtio
vm_boot_nic_type=82540EM
#vm_default_nic_type=82540EM
vm_default_nic_type=virtio

# By default, all available network interfaces vboxnet won't be removed,
# if their IP addresses don't match with instack_master_ips (10.20.0.1 172.16.0.254
# 172.16.1.1)
# If you want to remove all existing vbox interfaces, then use rm_network=1
# 0 - don't remove all vbox networks. Remove only instack networks if they exist
# 1 - remove all vbox networks
rm_network=0

# By Default, the undercloud isn not deleted when you run 'clean'. It must
# be deleted manually. Please set the following to '1' to have clean delete
# the undercloud as well.
rm_instack=0

# By default, if you have plenty of memory, pagefusion isn't used.
# If memory is scarce, then turn pagefusion on at the expense of more cpu usage.
vbox_vm_flags=""
vbox_vm_flags="${vbox_vm_flags} --pagefusion off"
vbox_vm_flags="${vbox_vm_flags} --nestedpaging on"
vbox_vm_flags="${vbox_vm_flags} --vtxvpid on"
vbox_vm_flags="${vbox_vm_flags} --vtxux on"
vbox_vm_flags="${vbox_vm_flags} --largepages on"
vbox_vm_flags="${vbox_vm_flags} --chipset piix3"
vbox_vm_flags="${vbox_vm_flags} --largepages on"
vbox_vm_flags="${vbox_vm_flags} --pae off"
vbox_vm_flags="${vbox_vm_flags} --longmode on"
vbox_vm_flags="${vbox_vm_flags} --hpet on"
vbox_vm_flags="${vbox_vm_flags} --hwvirtex on"
vbox_vm_flags="${vbox_vm_flags} --triplefaultreset off"

# Please add the IPs accordingly if you going to create non-default NICs number
# 10.20.0.1/24   - ctlplane
# 10.16.0.1/24  - OpenStack Public/External/Floating network
# 10.16.1.1/24  - OpenStack Fixed/Internal/Private network
# 192.168.0.1/24 - OpenStack Management network
# 192.168.1.1/24 - OpenStack Storage network (for Ceph, Swift etc)
instack_master_ips="10.20.0.1 10.16.0.1 10.16.1.1"

# Network mask for instack interfaces
mask="255.255.255.0"

# Determining the type of operating system and adding CPU core to the master node
case "$(uname)" in
	Linux)
		os_type="linux"
		if [ "$(nproc)" -gt "2" ]; then
			vm_master_cpu_cores=4
		else
			vm_master_cpu_cores=2
		fi
		;;
	Darwin)
		os_type="darwin"
		mac_nproc=`sysctl -a | grep machdep.cpu.thread_count | sed 's/^machdep.cpu.thread_count\:[ \t]*//'`
		if [ "${mac_nproc}" -gt "1" ]; then
			vm_master_cpu_cores=2
		else
			vm_master_cpu_cores=1
		fi
	;;
	CYGWIN*)
		os_type="cygwin"
		if [ "$(nproc)" -gt "1" ]; then
			vm_master_cpu_cores=2
		else
			vm_master_cpu_cores=1
		fi
		;;
	*)
		echo "$(uname) is not supported operating system."
		exit 1
		;;
esac

# Overcommit ratio (with nested paging and page fusion we can generally assume a 200% ratio)
vbox_overcommit_ratio=0.5

# Master node settings
vm_master_memory_mb=24576
vm_master_disk_mb=65535

# Master node access to the internet through the host system, using VirtualBox NAT adapter
#vm_master_nat_network=192.168.200.0/24
#vm_master_nat_gateway=192.168.200.2

# Master node access to the outside network (non-NAT)
vm_master_nat_network=10.20.0.0/24
vm_master_nat_gateway=10.20.0.2

# These settings will be used to check if master node has installed or not.
# If you modify networking params for master node during the boot time
#   (i.e. if you pressed Tab in a boot loader and modified params),
#   make sure that these values reflect that change.
vm_master_ip=10.20.0.2
vm_master_username=root
vm_master_password=r00tme
vm_master_prompt='root@instack ~]#'

# The number of nodes for installing OpenStack on
#   - for minimal non-HA installation, specify 2 (1 controller + 1 compute)
#   - for minimal non-HA with Cinder installation, specify 3 (1 ctrl + 1 compute + 1 cinder)
#   - for minimal HA installation, specify 4 (3 controllers + 1 compute)
if [ "${CONFIG_FOR}" = "128GB" ]; then
	cluster_size=16
elif [ "${CONFIG_FOR}" = "64GB" ]; then
	cluster_size=8
elif [ "${CONFIG_FOR}" = "16GB" ]; then
	cluster_size=5
elif [ "${CONFIG_FOR}" = "8GB" ]; then
	cluster_size=3
else
	# Section for custom configuration
	cluster_size=1
fi

# Slave node settings. This section allows you to define CPU count for each slave node.

# You can specify CPU count for your nodes as you wish, but keep in mind resources of your machine.
# If you don't, then will be used default parameter
if [ "${CONFIG_FOR}" = "128GB" ]; then
	vm_master_cpu_cores=2
	vm_slave_cpu_default=4

	vm_slave_cpu[1]=4
	vm_slave_cpu[2]=4
	vm_slave_cpu[3]=4
elif [ "${CONFIG_FOR}" = "64GB" ]; then
	vm_slave_cpu_default=2

	vm_slave_cpu[1]=4
	vm_slave_cpu[2]=4
	vm_slave_cpu[3]=4
elif [ "${CONFIG_FOR}" = "16GB" ]; then
	vm_slave_cpu_default=1

	vm_slave_cpu[1]=1
	vm_slave_cpu[2]=1
	vm_slave_cpu[3]=1
	vm_slave_cpu[4]=1
	vm_slave_cpu[5]=1
elif [ "${CONFIG_FOR}" = "8GB" ]; then
	vm_slave_cpu_default=1

	vm_slave_cpu[1]=1
	vm_slave_cpu[2]=1
	vm_slave_cpu[3]=1
else
	# Section for custom configuration
	vm_slave_cpu_default=1

	vm_slave_cpu[1]=1
fi

# This section allows you to define RAM size in MB for each slave node.
# Keep in mind that PXE boot might not work correctly with values lower than 768.
# You can specify memory size for the specific slaves, other will get default vm_slave_memory_default
# Mirantis OpenStack 3.2 controllers require 1280 MiB of RAM as absolute minimum due to Heat!

# You may comment out all the following memory parameters to use default value for each node.
# It is recommended if you going to try HA configurations.
# for controller node at least 1.5Gb is required if you also run Ceph and Heat on it
# and for Ubuntu controller we need 2Gb of ram

# For compute node 1GB is recommended, otherwise VM instances in OpenStack may not boot
# For dedicated Cinder, 768Mb is OK, but Ceph needs 1Gb minimum

if [ "${CONFIG_FOR}" = "128GB" ]; then
	vm_slave_memory_default=4128

	# Controllers
	vm_slave_memory_mb[1]=16384
	vm_slave_memory_mb[2]=16384
	vm_slave_memory_mb[3]=16384
	# Ceph
	vm_slave_memory_mb[4]=4128
	vm_slave_memory_mb[5]=4128
	vm_slave_memory_mb[6]=4128
	vm_slave_memory_mb[7]=4128
	vm_slave_memory_mb[8]=4128
elif [ "${CONFIG_FOR}" = "64GB" ]; then
	vm_slave_memory_default=4128

	# Controllers
	vm_slave_memory_mb[1]=8192
	vm_slave_memory_mb[2]=8192
	vm_slave_memory_mb[3]=8192
	# Ceph
	vm_slave_memory_mb[4]=4128
	vm_slave_memory_mb[5]=4128
	vm_slave_memory_mb[6]=4128
	vm_slave_memory_mb[7]=4128
	vm_slave_memory_mb[8]=4128
elif [ "${CONFIG_FOR}" = "16GB" ]; then
	vm_slave_memory_default=1536

	# Controllers
	vm_slave_memory_mb[1]=8192
	vm_slave_memory_mb[2]=8192
	vm_slave_memory_mb[3]=8192
	# Ceph
	vm_slave_memory_mb[4]=2048
	vm_slave_memory_mb[5]=2048
elif [ "${CONFIG_FOR}" = "8GB" ]; then
	vm_slave_memory_default=1024

	vm_slave_memory_mb[1]=1536
	vm_slave_memory_mb[2]=1536
	vm_slave_memory_mb[3]=1536
else
	# Section for custom configuration
	vm_slave_memory_default=1024

	vm_slave_memory_mb[1]=2048
fi

# Within demo cluster created by this script, all slaves (controller
# and compute nodes) will have identical disk configuration. Each
# slave will have three disks with sizes defined by the variables below. In a disk configuration
# dialog you will be able to allocate the whole disk or it's part for
# operating system (Base OS), VMs (Virtual Storage), Ceph or other function,
# depending on the roles applied to the server.
# Nodes with combined roles may require more disk space.
vm_slave_first_disk_mb=65535
vm_slave_second_disk_mb=8388608
vm_slave_extra_disk_mb=8388608

# Set to 1 to run VirtualBox in headless mode
headless=1
skipinstackmenu="no"
useserialconsole="yes"

# Override settings with vbox node-specific config
VBOX_CONFIG=".vbox_config_$(uname -n)"
if [ -f ${VBOX_CONFIG} ]; then
	echo "(II) Loading ${VBOX_CONFIG} ..."
	source ${VBOX_CONFIG}
fi
