#!/bin/bash
for i in $(seq 1 16)
do
	VM_NAME="osp-baremetal-${i}"
	MAC=$(vboxmanage showvminfo ${VM_NAME} --machinereadable|grep macaddress1|sed -e 's/.*="//' -e 's/"//'|sed 's/..\B/&:/g')
	echo	"${VM_NAME} : ${MAC}"
done
