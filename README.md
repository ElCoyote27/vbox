VirtualBox scripts for provisionning an OSP tripleo virtual infra.
==========================

Requirements
------------

- VirtualBox with VirtualBox Extension Pack
- procps
- expect
- Cygwin for Windows host PC
- Enable VT-x/AMD-V acceleration option on your hardware for 64-bits guests
- socat

Extra config
---

Create a config file with the VBbox information of your Hypervisor..
$ cat .vbox_creds 
# Hypervisor
VBOX_HOST=mybighyper
VBOX_HOST_IP=10.40.80.121
VBOX_USER=myuser
VBOX_USER_PWD=""
# VBOX_SSH_KEY_FILE must be local to the system where the script is run..
VBOX_SSH_KEY_FILE=$HOME/.ssh/id_rsa
# Instack IP or hostname
INSTACK_HOST=myinstack


Run
---

In order to successfully run OpenStack under VirtualBox, you need to:
- run "./launch.sh" (or "./launch\_8GB.sh", "./launch\_16GB.sh" or "./launch\_64GB.sh" according to your system resources).
  It will automatically pick up the vdi and spin up master node and slave nodes

If there are any errors, the script will report them and abort.

If you want to change settings (number of OpenStack nodes, CPU, RAM, HDD), please refer to "config.sh".

To shutdown VMs and clean environment just run "./clean.sh"

Extra Stuff
---
/usr/sbin/iptables -t nat -A POSTROUTING -o bond3 -j MASQUERADE
/usr/sbin/iptables-save > /etc/sysconfig/iptables

