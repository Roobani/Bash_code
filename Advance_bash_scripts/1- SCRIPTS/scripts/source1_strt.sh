#!/bin/bash
VM_DIR=/var/app/vmware/Sourceforge-1_VM/
VM_IMG=SourceForge-1.vmx
EMAILID="john@sodexis.com"
export DISPLAY=":1001.0"

STATE=`vmrun list | grep $VM_DIR$VM_IMG |wc -l`

# grep for state = 0, then VM is not runing

if [ $STATE -eq 0 ]; then
     export VM_DIR
     export VM_IMG
     echo "Starting vmware image $VM_IMG"	
     su admin -c 'vmrun -T ws start $VM_DIR$VM_IMG && sleep 5 && exit 0'
else
     T=/tmp/sourceforgest1.mail
     echo "DATE: $(date)">$T
     echo " " >>$T
     echo "Hostname: $(hostname)" >>$T
     echo " " >>$T
     echo "Sourcforge-1 VM backup - Unable to perform startup, VM is already running. Check backup were done sucessfully without VM Shutdown." >>$T
     mail -s "ERROR - Sourceforge-1 VM starting" "$EMAILID" <$T
     rm -f $T
fi
exit 0

