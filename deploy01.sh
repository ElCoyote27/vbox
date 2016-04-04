#!/bin/bash
set -x
openstack overcloud deploy --templates \
	--ntp-server 10.0.128.246 \
	--control-scale 3 --compute-scale 1 \
	--neutron-tunnel-types vxlan --neutron-network-type vxlan
