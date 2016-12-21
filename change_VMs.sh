#!/bin/bash
# NIC types. Boot NIC must be intel or AMD. Other NICs can be virtio
# Types: 82540EM, 82545EM, 82543GC, Am79C973, virtio
vbox_vm_flags=""
vbox_vm_flags="${vbox_vm_flags} --pagefusion on"
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

echo "Final flags: ${vbox_vm_flags}"

for i in {1..16}
do
	name="osp-baremetal-${i}"
	VBoxManage modifyvm ${name} ${vbox_vm_flags}
done

for i in 1
do
	name="osp-instack"
	VBoxManage modifyvm ${name} ${vbox_vm_flags}
done

