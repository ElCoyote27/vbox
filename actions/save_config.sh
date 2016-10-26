#!/bin/bash

#
# This script saves the defaults picked by the end-user
#

source ./config.sh
source ./functions/memory.sh

VBOX_CONF=".config"

/bin/rm -f ${VBOX_CONF}
for value in \
	vm_boot_nic_type vm_default_nic_type \
	vm_master_cpu_cores vm_master_memory_mb vm_master_disk_mb \
	cluster_size vm_slave_cpu_default vm_slave_memory_default \
	vm_slave_first_disk_mb hypervisor_bridged_nic_list vbox_vm_flags
do
	if [ "x$(eval echo \$${value})" != "x" ]; then
		echo "${value}=\"$(eval echo \$${value})\"" >> ${VBOX_CONF}
	fi
done
