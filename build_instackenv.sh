#!/bin/bash
#
# Requirements: This script must be capable of:
# sudo ssh ${INSTACK_HOST_IP} -l root
#   and:
# sudo ssh ${INSTACK_HOST_IP} -l root "su - stack -c 'ssh ${VBOX_HOST_IP} -l ${VBOX_USER} VBoxManage'"
#

# Initial setup
source ./config.sh
source ./functions/memory.sh
VBOX_CONF=".config"
source ${VBOX_CONF}
IRONIC_KEY="/home/stack/.ssh/ironic_key"
VBOX_CREDS=".vbox_creds_$(uname -n)"

# Credentials
if [ -f ${VBOX_CREDS} ]; then
	. ${VBOX_CREDS}
else
	echo "NO credentials for VBOX Manager found in ./.vbox_creds_$(uname -n)!" ; exit 127
fi

# Get the IP of the VBOX hypervisor
VBOX_HOST_IP=$(/usr/bin/getent ahosts ${VBOX_HOST}|awk '/STREAM/ { print $1 }')
if [ "x${VBOX_HOST_IP}" = "x" ]; then
	echo "Unable to find IP for ${VBOX_HOST}" ; exit 127
fi
# Get the IP of the Instack VM
INSTACK_HOST_IP=$(/usr/bin/getent ahosts ${INSTACK_HOST}|awk '/STREAM/ { print $1 }')
if [ "x${INSTACK_HOST_IP}" = "x" ]; then
	echo "Unable to find IP for ${INSTACK_HOST}" ; exit 127
fi

# Sanity Check
ssh -q stack@${INSTACK_HOST_IP} test -f stackrc
if [ $? -ne 0 ]; then
	echo "(EE) Stack not installed or no \$HOME/stackrc file found!"
	exit 127
fi

#cat << EOF
cat << EOF > instackenv.json
{
  "ssh-user": "${VBOX_USER}",
  "ssh-key": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
  "ssh_virt_type": "vbox",
      "vbox_use_headless":"true",
  "power_manager": "nova.virt.baremetal.virtual_power_driver.VirtualPowerManager",
  "host-ip": "${VBOX_HOST_IP}",
  "arch": "x86_64",
  "nodes": [
    {
      "name": "osp-baremetal-1",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-1 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
            "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-2",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-2 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-3",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-3 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-4",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-4 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-5",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-5 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-6",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-6 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-7",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-7 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-8",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-8 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-9",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-9 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-10",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-10 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-11",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-11 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-12",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-12 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-13",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-13 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-14",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-14 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-15",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-15 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    },
    {
      "name": "osp-baremetal-16",
      "pm_addr": "${VBOX_HOST_IP}",
      "pm_password": "$(cat ~/.ssh/id_rsa|awk '{printf "%s\\n", $0}')",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(ssh -l ${VBOX_USER} -i ~/.ssh/id_rsa ${VBOX_HOST_IP} vboxmanage showvminfo osp-baremetal-16 --machinereadable|sed -e '/macaddress1/!d' -e 's/macaddress1=//' -e 's/"//g' -e 's/..\B/&:/g')"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "${VBOX_USER}",
      "ssh_virt_type": "vbox",
      "vbox_use_headless":"true"
    }
  ]
}
EOF
