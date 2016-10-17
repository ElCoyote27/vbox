#!/bin/bash
VBOX_DIR=/shared/vbox0/VM

sudo -u root /usr/bin/VBoxManage setproperty machinefolder ${VBOX_DIR}

sudo -u $(/usr/bin/id -un) /usr/bin/VBoxManage setproperty machinefolder ${VBOX_DIR}
