#!/bin/bash
# NIC types. Boot NIC must be intel or AMD. Other NICs can be virtio
# Types: 82540EM, 82545EM, 82543GC, Am79C973, virtio
vm_boot_nic_type=82540EM
vm_default_nic_type=82540EM
rom_path=$(ls -d $(pwd)/rom/*.rom 2>/dev/null | head -1)

for i in {1..16}
do
	name="osp-baremetal-${i}"
	VBoxManage modifyvm ${name} --nictype1 ${vm_boot_nic_type}
	VBoxManage modifyvm ${name} --nictype2 ${vm_default_nic_type}
	VBoxManage modifyvm ${name} --nictype3 ${vm_default_nic_type}
	VBoxManage modifyvm ${name} --nictype4 ${vm_default_nic_type}

	#VBoxManage modifyvm ${name} --nic2 bridged --bridgeadapter2 bond3
	#VBoxManage modifyvm ${name} --nic3 bridged --bridgeadapter3 bond3
	VBoxManage modifyvm ${name} --nic2 hostonly --hostonlyadapter2 vboxnet1
	VBoxManage modifyvm ${name} --nic3 hostonly --hostonlyadapter3 vboxnet1
        if [ "x${vm_boot_nic_type}" = "xvirtio" -a "x${rom_path}" != "x" ]; then
                if [ -f ${rom_path} ]; then
                        VBoxManage setextradata ${name} VBoxInternal/Devices/pcbios/0/Config/LanBootRom ${rom_path}
                fi
	else
		VBoxManage setextradata ${name} VBoxInternal/Devices/pcbios/0/Config/LanBootRom
        fi
done

for i in 1
do
	name="osp-instack"
	VBoxManage modifyvm ${name} --nictype1 ${vm_boot_nic_type}
	VBoxManage modifyvm ${name} --nictype2 ${vm_default_nic_type}
	VBoxManage modifyvm ${name} --nictype3 ${vm_default_nic_type}
	VBoxManage modifyvm ${name} --nictype4 ${vm_default_nic_type}

	#VBoxManage modifyvm ${name} --nic2 bridged --bridgeadapter2 bond3
	#VBoxManage modifyvm ${name} --nic3 bridged --bridgeadapter3 bond3
	VBoxManage modifyvm ${name} --nic2 hostonly --hostonlyadapter2 vboxnet1
	VBoxManage modifyvm ${name} --nic3 hostonly --hostonlyadapter3 vboxnet2
done

