#!/bin/bash
VM_DIR=/var/app/vmware/NagiosXI_VM/
VM_IMG=NagiosXI_VM.vmx
EMAILID="john@sodexis.com"
export DISPLAY=":1001.0"

STATE=$(vmrun list | grep "$VM_DIR$VM_IMG" | wc -l)

# grep for state = 1, if [1] then VM is running

if [ "$STATE" -eq "1" ]; then
     echo "Suspending vmware image $VM_IMG"
     vmrun -T ws stop $VM_DIR$VM_IMG soft
     sleep 180
     STATE1=$(vmrun list | grep $VM_DIR$VM_IMG |wc -l)
        if [ "$STATE1" -eq "1" ]; then
        echo "NagiosXI_VM not stopped, even after "vmrun stop" cmd executed" | mail -s "ERROR - NagiosXI_VM Backup" $EMAILID
        exit 1
	fi
else
     T=/tmp/nagios.mail
     echo "DATE: $(date)">$T
     echo " " >>$T
     echo "Hostname: $(hostname)" >>$T
     echo " " >>$T
     echo "NagiosXI VM found already in stopped STATE=0" >>$T
     mail -s "ERROR - NagiosXI VM Backup" "$EMAILID" <$T
     rm -f $T
fi
exit 0
