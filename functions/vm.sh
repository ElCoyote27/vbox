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

# This file contains the functions to manage VMs in through VirtualBox CLI

get_hypervisor_bridged_nic() {
	if [ "x${hypervisor_bridged_nic_list}" != "x" ];then
		for myif in ${hypervisor_bridged_nic_list}
		do
			if [ -d /sys/class/net/${myif} ]; then
				>&2  echo "Selected Bridged NIC: ${myif}"
				echo ${myif}
				break
			fi
		done
	fi
}

get_vm_base_path() {
	echo `VBoxManage list systemproperties | grep '^Default machine folder' | sed 's/^Default machine folder\:[ \t]*//'`
}

get_vms_running() {
	echo `VBoxManage list runningvms | sed -e 's/[ \t]*{.*}//' -e 's/^"//' -e 's/"$//' |grep "^${vm_name_prefix}"`
}

get_vms_present() {
	echo `VBoxManage list vms | sed -e 's/[ \t]*{.*}//' -e 's/^"//' -e 's/"$//' |grep "^${vm_name_prefix}"`
}

is_vm_running() {
	name=${1}
	list=$(get_vms_running)

	# Check that the list of running VMs contains the given VM
	for name_in_list in ${list}; do
		if [[ "${name_in_list}" == "${name}" ]]; then
			return 0
		fi
	done
	return 1
}

is_vm_present() {
	name=${1}
	list=$(get_vms_present)

	for name_in_list in ${list}; do
		if [[ "${name_in_list}" == "${name}" ]]; then
			return 0
		fi
	done
	return 1
}

check_running_vms() {
	OIFS=${IFS}
	IFS=","
	local hostonly_interfaces=${1}
	local list_running_vms=$(VBoxManage list runningvms | sed -e 's/\" {/\",{/g' | grep "^${vm_name_prefix}" )
	for vm_name in ${list_running_vms}; do
		vm_name=$(echo ${vm_name} | grep "\"" | sed 's/"//g')
		vm_names+="${vm_name},"
	done
	for i in ${vm_names}; do
		for j in ${hostonly_interfaces}; do
			running_vm=`VBoxManage showvminfo ${i} | grep "${j}"`
			if [[ $? -eq 0 ]]; then
				echo "The \"${i}\" VM uses host-only interface \"${j}\" and it cannot be removed...."
				echo "You should turn off the \"${i}\" virtual machine, run the script again and then the host-only interface will be deleted. Aborting..."
				exit 1
			fi
		done
	done
	IFS=${OIFS}
}

create_vm() {
	name=${1}
	nic=${2}
	cpu_cores=${3}
	memory_mb=${4}
	disk_mb=${5}
	os='RedHat_64'

	# There is a chance that some files are left from previous VM instance
	vm_base_path=$(get_vm_base_path)
	vm_path="${vm_base_path}/${name}/"
	rm -rf "${vm_path}"

	# Create virtual machine with the right name and type (assuming CentOS)
	VBoxManage createvm --name ${name} --ostype ${os} --register

	# Set the real-time clock (RTC) operate in UTC time
	# Set memory and CPU parameters
	# Set video memory to 64MB, so VirtualBox does not complain about "non-optimal" settings in the UI
	VBoxManage modifyvm ${name} --rtcuseutc on --memory ${memory_mb} --cpus ${cpu_cores} --vram 64

	# Disable Page Fusion, Enable Large Pages and Nested Paging..
	set -x
	VBoxManage modifyvm ${name} --pagefusion ${vbox_page_fusion} --nestedpaging on --vtxvpid on --largepages on
	set +x

	# Set Paravirtualization driver..
	VBoxManage modifyvm ${name} --paravirtprovider kvm

	# Change chipset to ICH9 or PIIX3
	VBoxManage modifyvm ${name} --chipset piix3
	# VBoxManage modifyvm ${name} --chipset ich9

	# Configure main network interface for management/PXE network
	add_hostonly_adapter_to_vm ${name} 1 "${nic}" ${vm_boot_nic_type}

	# Fix the iPXE rom thing if driver is virtio
	# More info here: http://etherboot.org/wiki/romburning/vbox
	# And here: https://github.com/SpencerBrown/virtualbox-ipxe
	# 
	# So here's the catch: VBox doesn't have an iPXE rom for virtio.
	# You could build a ROM from www.ipxe.org but VBox would fail to use
	# it as it discards ROMs larger than 56K PXE roms..
	#
	# Lucklily, deep within the vbox source there's an ipxe that can be modified
	# to support bzImage -and- be less than 56k.. This build is provided in the rom
	# subdir. I built that image with 5.0.20SVN like this:
	# cd src/VBox/Devices/PC/ipxe
	# gmake -j4 DEBUG=script bin/1af41000.rom

	if [ "x${vm_boot_nic_type}" = "xvirtio" -a "x${rom_path}" != "x" ]; then
		if [ -f ${rom_path} ]; then
			VBoxManage setextradata ${name} VBoxInternal/Devices/pcbios/0/Config/LanBootRom ${rom_path}
		fi
	fi

	VBoxManage modifyvm ${name} --boot1 disk --boot2 dvd --boot3 net --boot4 none

	# Configure storage controllers
	VBoxManage storagectl ${name} --name 'IDE' --add ide --hostiocache on --controller ICH6
	VBoxManage storagectl ${name} --name 'SATA' --add sata --hostiocache on --controller IntelAHCI --portcount 16

	# Add first serial port (All VMs)
	VBoxManage modifyvm ${name} --uart1 0x3F8 4
	VBoxManage modifyvm ${name} --uartmode1 server "${HOME}/serial-${name}"
	# Not: b1152000 is not a typo (it's ten times faster than 115200 if your VBox supports it)
	echo "Serial Port: socat unix-connect:${HOME}/serial-${name} stdio,raw,sane,echo=0,icanon=0,escape=0x11,b1152000"|tee -a ${vm_serial_info}
	echo "Serial Port: CTRL-q to disconnect"|tee -a ${vm_serial_info}

	# Create and attach the main hard drive
	add_disk_to_vm ${name} 0 ${disk_mb}

	# Expose Memory
	VBoxManage setextradata ${vm_name} "VBoxInternal/Devices/pcbios/0/Config/DmiExposeMemoryTable" "1"
}

add_hostonly_adapter_to_vm() {
	name=${1}
	id=${2}
	nic=${3}
	vm_nic_type=${4}

	echo "Adding hostonly adapter to ${name} and bridging with host NIC ${nic}, type ${vm_nic_type}..."
	# Add Intel PRO/1000 MT Desktop (82540EM) card to VM. The card is 1Gbps.
	VBoxManage modifyvm ${name} --nic${id} hostonly --hostonlyadapter${id} "${nic}" --nictype${id} ${vm_nic_type} \
	--cableconnected${id} on --macaddress${id} auto
	VBoxManage modifyvm  ${name} --nicpromisc${id} allow-all
}

add_nat_adapter_to_vm() {
	name=${1}
	id=${2}
	nat_network=${3}
	vm_nic_type=${4}

	echo "Adding NAT adapter to ${name} for outbound network access through the host system, type ${vm_nic_type}..."
	# Add Intel PRO/1000 MT Desktop (82540EM) card to VM. The card is 1Gbps.
	VBoxManage modifyvm ${name} --nic${id} nat --nictype${id} ${vm_nic_type} \
	--cableconnected${id} on --macaddress${id} auto --natnet${id} "${nat_network}"
	VBoxManage modifyvm  ${name} --nicpromisc${id} allow-all
	VBoxManage controlvm ${name} setlinkstate${id} on
}

add_bridge_adapter_to_vm() {
	name=${1}
	id=${2}
	nic=${3}
	vm_nic_type=${4}

	echo "Adding Bridge adapter to ${name} for outbound network access through the host network, type ${vm_nic_type}..."
	# Add Intel PRO/1000 MT Desktop (82540EM) card to VM. The card is 1Gbps.
	VBoxManage modifyvm ${name} --nic${id} bridged --nictype${id} ${vm_nic_type} \
	--cableconnected${id} on --macaddress${id} auto --bridgeadapter${id} "${nic}"
	VBoxManage modifyvm  ${name} --nicpromisc${id} allow-all
}

add_disk_to_vm() {
	vm_name=${1}
	port=${2}
	disk_mb=${3}

	echo "Adding disk to ${vm_name}, with size ${disk_mb} Mb..."

	vm_disk_path="$(get_vm_base_path)/${vm_name}/"
	disk_name="${vm_name}_${port}"
	disk_filename="${disk_name}.vdi"
	src_filename="images/${disk_filename}"
	if [ -f "${src_filename}" ]; then
		echo -n "Copying ${src_filename} to ${vm_disk_path}/${disk_filename}....."
		cp -f "${src_filename}" "${vm_disk_path}/${disk_filename}" && echo "Done"
	else
		VBoxManage createhd --filename "${vm_disk_path}/${disk_filename}" --size ${disk_mb} --format VDI
	fi
	VBoxManage storageattach ${vm_name} --storagectl 'SATA' --port ${port} --device 0 --type hdd --medium "${vm_disk_path}/${disk_filename}"

	# Add serial numbers of disks to slave nodes
	echo "Adding serial numbers of disks to ${vm_name}..."
	VBoxManage setextradata ${vm_name} "VBoxInternal/Devices/ahci/0/Config/Port${port}/SerialNumber" "VBOX-OSP-VHD${port}"
}

delete_vm() {
	name=${1}
	vm_base_path=$(get_vm_base_path)
	vm_path="${vm_base_path}/${name}/"

	# Power off VM, if it's running
	count=0
	while is_vm_running ${name}; do
		echo "Stopping Virtual Machine ${name}..."
		VBoxManage controlvm ${name} poweroff
		if [[ "${count}" != 5 ]]; then
			count=$((count+1))
			sleep 5
		else
			echo "VirtualBox cannot stop VM ${name}... Exiting"
			exit 1
		fi
	done

	echo "Deleting existing virtual machine ${name}..."
	while is_vm_present ${name}
	do
		VBoxManage unregistervm ${name} --delete
	done
	# Virtualbox does not fully delete VM file structure, so we need to delete the corresponding directory with files as well
	rm -rf "${vm_path}"
}

delete_vms_multiple() {
	name_prefix=${1}
	list=$(get_vms_present)

	# Loop over the list of VMs and delete them, if its name matches the given refix
	for name in ${list}; do
		if [[ ${name} == ${name_prefix}* ]]; then
			echo "Found existing VM: ${name}. Deleting it..."
			delete_vm ${name}
		fi
	done
}

delete_slave_vms_multiple() {
	name_prefix=${1}
	list=$(get_vms_present|sed -e "s@${name_prefix}instack@@")

	# Loop over the list of VMs and delete them, if its name matches the given refix
	for name in ${list}; do
		if [[ ${name} == ${name_prefix}* ]]; then
			echo "Found existing VM: ${name}. Deleting it..."
			delete_vm ${name}
		fi
	done
}

stop_vm() {
	name=${1}
	vm_base_path=$(get_vm_base_path)
	vm_path="${vm_base_path}/${name}/"

	# Power off VM, if it's running
	count=0
	while is_vm_running ${name}; do
		echo "Stopping Virtual Machine ${name}..."
		VBoxManage controlvm ${name} poweroff
		if [[ "${count}" != 5 ]]; then
			count=$((count+1))
			sleep 5
		else
			echo "VirtualBox cannot stop VM ${name}... Exiting"
			exit 1
		fi
	done
}

stop_vms_multiple() {
	name_prefix=${1}
	list=$(get_vms_present)

	# Loop over the list of VMs and delete them, if its name matches the given refix
	for name in ${list}; do
		if [[ ${name} == ${name_prefix}* ]]; then
			echo "Found existing VM: ${name}. Stopping it..."
			stop_vm ${name}
		fi
	done
}

stop_slave_vms_multiple() {
	name_prefix=${1}
	list=$(get_vms_present|sed -e "s@${name_prefix}instack@@")

	# Loop over the list of VMs and delete them, if its name matches the given refix
	for name in ${list}; do
		if [[ ${name} == ${name_prefix}* ]]; then
			echo "Found existing VM: ${name}. Stopping it..."
			stop_vm ${name}
		fi
	done
}

start_vms_multiple() {
	name_prefix=${1}
	list=$(get_vms_present)

	# Loop over the list of VMs and delete them, if its name matches the given refix
	for name in ${list}; do
		if [[ ${name} == ${name_prefix}* ]]; then
			echo "Found existing VM: ${name}. Starting it..."
			start_vm ${name}
			sleep 2
		fi
	done
}

start_vm() {
	name=${1}

	# Check if we are starting the undercloud VM... If we kept it from a previous
	# install, make sure Page Fusion is set accordingly...
	if [ "x${name}"  = "x${vm_name_prefix}instack" -a "x${rm_instack}" = "x0" ]; then
		VBoxManage modifyvm ${name} --pagefusion ${vbox_page_fusion} 
	fi

	count=0
	while ! is_vm_running ${name}; do
		echo "Starting Virtual Machine ${name}..."
		# Just start it
		if [[ ${headless} == 1 ]]; then
			VBoxManage startvm ${name} --type headless
		else
			VBoxManage startvm ${name}
		fi
		if [[ "${count}" != 5 ]]; then
			count=$((count+1))
			sleep 5
		else
			echo "VirtualBox cannot start VM ${name}... Exiting"
			exit 1
		fi
	done
}

mount_iso_to_vm() {
	name=${1}
	iso_path=${2}

	# Mount ISO to the VM
	VBoxManage storageattach ${name} --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "${iso_path}"
}

enable_network_boot_for_vm() {
	name=${1}

	# Set the right boot priority
	VBoxManage modifyvm ${name} --boot1 net --boot2 disk --boot3 none --boot4 none --nicbootprio1 1
}

