#!/bin/bash
version=$(vboxmanage -v)
var1=$(echo ${version} | cut -d 'r' -f 1)
var2=$(echo ${version} | cut -d 'r' -f 2)
file="Oracle_VM_VirtualBox_Extension_Pack-${var1}-${var2}.vbox-extpack"
if [ -f ${file} ]; then
	echo "Installing extpack: ${file}"
	sudo VBoxManage extpack install ${file} --replace
	sudo VBoxManage list extpacks
else
	echo "Unable to find extpack at: ${file}!"
	exit 1
fi
