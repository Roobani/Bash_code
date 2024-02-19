#!/bin/bash
VM_DIR=/var/app/vmware/Sourceforge_VM/
VM_IMG=SourceForge_VM.vmx
EMAILID="john@sodexis.com"
export DISPLAY=":1001.0"
STATE=`vmrun list | grep $VM_DIR$VM_IMG |wc -l`

# grep for state = 0, then VM is not runing

if [ "$STATE" -eq "0" ]; then
     echo "Starting vmware image $VM_IMG"
     vmrun -T ws start $VM_DIR$VM_IMG 
else
     T=/tmp/sourceforgest.mail
     echo "DATE: $(date)">$T
     echo " " >>$T
     echo "Hostname: $(hostname)" >>$T
     echo " " >>$T
     echo "Sourcforge VM backup - Unable to perform startup, VM is already running. Check backup were done sucessfully without VM Shutodown." >>$T
     mail -s "ERROR - Sourceforge VM starting" "$EMAILID" <$T
     rm -f $T
fi
exit 0

