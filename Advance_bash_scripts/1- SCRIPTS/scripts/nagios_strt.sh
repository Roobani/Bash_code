#!/bin/bash
VM_DIR=/var/app/vmware/NagiosXI_VM/
VM_IMG=NagiosXI_VM.vmx
EMAILID="john@sodexis.com"
export DISPLAY=":1001.0"
STATE=`vmrun list | grep $VM_DIR$VM_IMG |wc -l`

# grep for state = 0, then VM is not runing

if [ $STATE -eq 0 ]; then
     echo "Starting vmware image $VM_IMG"
     vmrun -T ws start $VM_DIR$VM_IMG && sleep 5
else
     T=/tmp/nagios1.mail
     echo "DATE: $(date)">$T
     echo " " >>$T
     echo "Hostname: $(hostname)" >>$T
     echo " " >>$T
     echo "NagiosXI VM backup - Unable to perform startup, VM is already running. Check backup were done sucessfully without VM Shutodown." >>$T
     mail -s "ERROR - NagiosXI VM starting" "$EMAILID" <$T
     rm -f $T
fi
exit 0

