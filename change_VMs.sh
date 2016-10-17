#!/bin/bash
# NIC types. Boot NIC must be intel or AMD. Other NICs can be virtio
# Types: 82540EM, 82545EM, 82543GC, Am79C973, virtio
VFLAGS="--pagefusion off --nestedpaging on --vtxvpid on --largepages on --pae off"

for i in {1..16}
do
	name="osp-baremetal-${i}"
	VBoxManage modifyvm ${name} ${VFLAGS}
done

for i in 1
do
	name="osp-instack"
	VBoxManage modifyvm ${name} ${VFLAGS}
done

