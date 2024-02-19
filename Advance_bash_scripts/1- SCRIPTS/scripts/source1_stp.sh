#!/bin/bash
VM_DIR=/var/app/vmware/Sourceforge-1_VM/
VM_IMG=SourceForge-1_VM.vmx
EMAILID="john@sodexis.com"
export DISPLAY=":1001.0"

STATE=`vmrun list | grep $VM_DIR$VM_IMG |wc -l`

# grep for state = 1, if [1] then VM is running

if [ $STATE -eq 1 ]
then
     export VM_DIR
     export VM_IMG
     echo "Suspending vmware image $VM_IMG"
     su admin -c 'vmrun -T ws stop $VM_DIR$VM_IMG soft && sleep 180 && exit 0'
	if [ $STATE1 -eq 0 ]; then
        echo "Sourceforge-1 VM not stopped, even after "vmrun stop" cmd executed" | mail -s "ERROR - Sourceforge-1 VM Backup" $EMAILID
        exit 1
	fi
else
     T=/tmp/sourceforge1.mail
     echo "DATE: $(date)">$T
     echo " " >>$T
     echo "Hostname: $(hostname)" >>$T
     echo " " >>$T
     echo "Sourceforge-1 VM found already in stopped STATE=0" >>$T
     mail -s "ERROR - Sourceforge-1 VM Backup" "$EMAILID" <$T
     rm -f $T

fi
exit 0
