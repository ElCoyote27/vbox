#!/bin/bash

#
# This script saves the defaults picked by the end-user
#

source ./config.sh
source ./functions/memory.sh

MYCONF=".config"

/bin/rm -f ${MYCONF}
for value in \
	vm_boot_nic_type vm_default_nic_type \
	vm_master_cpu_cores vm_master_memory_mb vm_master_disk_mb \
	cluster_size vm_slave_cpu_default vm_slave_memory_default \
	vm_slave_first_disk_mb
do
	echo "${value}=$(eval echo \$${value})" >> ${MYCONF}
done
