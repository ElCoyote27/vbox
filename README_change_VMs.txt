--pae on|off: This enables/disables PAE (see Section 3.4.2, “"Processor" tab”).

--longmode on|off: This enables/disables long mode (see Section 3.4.2, 
“"Processor" tab”).

--cpu-profile <host|intel 80[86|286|386]>: Indicate the use of a profile for guest 
cpu emulation. Specify either one based on the host system CPU (host), or one from 
a number of older Intel Micro-architectures - 8086, 80286, 80386.

--hpet on|off: This enables/disables a High Precision Event Timer (HPET) which can 
replace the legacy system timers. This is turned off by default. Note that Windows 
supports a HPET only from Vista onwards.

--hwvirtex on|off: This enables or disables the use of hardware virtualization 
extensions (Intel VT-x or AMD-V) in the processor of your host system; see Section 
10.3, “Hardware vs. software virtualization”.

--triplefaultreset on|off: This setting allows to reset the guest instead of 
triggering a Guru Meditation. Some guests raise a triple fault to reset the CPU so 
sometimes this is desired behavior. Works only for non-SMP guests.

--apic on|off: This setting enables(default)/disables IO APIC. With I/O APIC, 
operating systems can use more than 16 interrupt requests (IRQs) thus avoiding IRQ 
sharing for improved reliability. See Section 3.4.1, “"Motherboard" tab”.

--x2apic on|off: This setting enables(default)/disables CPU x2APIC support. CPU 
x2APIC support helps operating systems run more efficiently on high core count 
configurations, and optimizes interrupt distribution in virtualized environments. 
Disable when using host/guest operating systems incompatible with x2APIC support.

--paravirtprovider none|default|legacy|minimal|hyperv|kvm: This setting specifies 
which paravirtualization interface to provide to the guest operating system. 
Specifying none explicitly turns off exposing any paravirtualization interface. 
The option default, will pick an appropriate interface depending on the guest OS 
type while starting the VM. This is the default option chosen while creating new 
VMs. The legacy option is chosen for VMs which were created with older VirtualBox 
versions and will pick a paravirtualization interface while starting the VM with 
VirtualBox 5.0 and newer. The minimal provider is mandatory for Mac OS X guests, 
while kvm and hyperv are recommended for Linux and Windows guests respectively. 
These options are explained in detail under Section 10.4, “Paravirtualization 
providers”.

--paravirtdebug <key=value> [,<key=value> ...]: This setting specifies debugging 
options specific to the paravirtualization provider configured for this VM. Please 
refer to the provider specific options under Section 9.32, “Paravirtualized 
debugging” for a list of supported key-value pairs for each provider.

--nestedpaging on|off: If hardware virtualization is enabled, this additional 
setting enables or disables the use of the nested paging feature in the processor 
of your host system; see Section 10.3, “Hardware vs. software virtualization”.

--largepages on|off: If hardware virtualization and nested paging are enabled, for 
Intel VT-x only, an additional performance improvement of up to 5% can be obtained 
by enabling this setting. This causes the hypervisor to use large pages to reduce 
TLB use and overhead.

--vtxvpid on|off: If hardware virtualization is enabled, for Intel VT-x only, this 
additional setting enables or disables the use of the tagged TLB (VPID) feature in 
the processor of your host system; see Section 10.3, “Hardware vs. software 
virtualization”.

--vtxux on|off: If hardware virtualization is enabled, for Intel VT-x only, this 
setting enables or disables the use of the unrestricted guest mode feature for 
executing your guest.

--accelerate3d on|off: This enables, if the Guest Additions are installed, whether 
hardware 3D acceleration should be available; see Section 4.5.1, “Hardware 3D 
acceleration (OpenGL and Direct3D 8/9)”.
