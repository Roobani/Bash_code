#!/bin/sh


VMWARE_DIR="/var/app/vmware/sourceforge/";
VMWARE_VMX="$VMWARE_DIR/$2";
TAR_NAME="$3.tar";
COMPRESSION="$4";

echo "Virtual Machine Directory $VMWARE_DIR";
echo "Virtual Machine VMX File $VMWARE_VMX";
echo "Output Tar Name $TAR_NAME";
echo "Compression $COMPRESSION";

echo "Starting backup at `date`";

STATE=`vmware-cmd "$VMWARE_VMX" getstate|grep on|wc -l`

\# grep for state = on, if its there then suspend

if \[ $STATE -eq 1 ]
then
     echo "Suspending vmware image '$VMWARE_VMX'";
     vmware-cmd "$VMWARE_VMX" suspend;
     checkResult "Unable to suspend the vmware image $VMWARE_VMX";
fi

echo "Taring VMWare directory $VMWARE_DIR";

tar cvf "$TAR_NAME" "$VMWARE_DIR";

checkResult "Unable to create the file $TAR_NAME";

echo "Tar completed"

#Check if the state is suspended, of so resume the guest

STATE=`vmware-cmd "$VMWARE_VMX" getstate|grep suspended|wc -l`

if \[ $STATE -eq 1 ]
then
     echo "starting vmware image '$VMWARE_VMX'";
     vmware-cmd "$VMWARE_VMX" start;
     checkResult "Unable to resume the vmware image $VMWARE_VMX";
     echo "Image resumed at `date`"
fi

case $COMPRESSION in
     bzip)
          echo "Bzip2ing the file" 
          bzip2 "$TAR_NAME"
          checkResult "Unable to bzip2 the tar"          
     ;;

     #gzip the file
     gzip)
          echo "Gzipping file"
          gzip "$TAR_NAME"
          checkResult "Unable to Gzip the tar"          
     ;;

     #default case, print out tar name
     *)
          echo "Output file is '$TAR_NAME'";
     ;;

esac

echo "Finished backup at `date`";