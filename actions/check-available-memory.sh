#!/bin/bash

#    Copyright 2014 Mirantis, Inc.
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
# This script check available memory on host PC for quality provision VMs via VirtualBox
#

source ./config.sh
source ./functions/memory.sh

total_memory=$(get_available_memory)

if [ ${total_memory} -eq -1 ]; then
	echo "Launch without checking RAM on host PC"
	echo "Auto check memory is unavailable, you need install 'free'. Please install procps package."
else
	# Count selected RAM configuration
	for machine_number in $(eval echo {1..${cluster_size}}); do
		if [ -n "${vm_slave_memory_mb[${machine_number}]}" ]; then
			vm_total_mb=$(( ${vm_total_mb} + ${vm_slave_memory_mb[${machine_number}]} ))
		else
			vm_total_mb=$(( ${vm_total_mb} + ${vm_slave_memory_default} ))
		fi
	done
	vm_total_mb=$(echo "scale=0;(( ${vm_total_mb} + ${vm_master_memory_mb} ) * ${vbox_overcommit_ratio})/1" |bc)

	# Do not run VMs if host PC not have enough RAM
	can_allocate_mb=$(( (${total_memory} - 524288) / 1024 ))
	if [ ${vm_total_mb} -gt ${can_allocate_mb} ]; then
		echo "(**) Cannot use more than ${can_allocate_mb}MB, but was trying to run VMs with ${vm_total_mb}MB"
		# Assuming a further 0.5 ratio for PageFusion
		vm_total_mb=$(echo "scale=0;(( ${vm_total_mb} + ${vm_master_memory_mb} ) * ${vbox_overcommit_ratio}) * 0.5 /1" |bc)
		if [ ${vm_total_mb} -gt ${can_allocate_mb} ]; then
			echo "(**) Your host does NOT have enough memory (${vm_total_mb}MB needed with Page Fusion)."
			echo "(**) Even with overcommit and Page Fusion enabled, not enough memory is available! Exit!"
			exit 1
		else
			echo "(II) Forcing VBox Pagefusion to 'on' and continuing (assuming ${vm_total_mb}MB needed)..."
			vbox_page_fusion="on"
			if [ -f ./.config ]; then
				sed -i -e 's/vbox_page_fusion=off/vbox_page_fusion=on/' ./.config
			fi
		fi
	else
		echo "(II) Assuming ${vbox_overcommit_ratio} memory overcommit ratio ( ${vm_total_mb} MB needed, ${can_allocate_mb} MB available)"
	fi
fi
