#!/bin/bash

VMRUN="$(which vmrun)"

#---------------------------------------------------------------------------------------------------------------------
# CHANGE the below values with respect to order of VM names given in -j argument.  
# If Sourceforge_VM is given 1st in order under -J , then 
# VM_0_CONST_CPU_MAX should be its MAX CPU in %,
# VM_0_CONST_GUEST_USR should be the login user of virtual machine.,
# VM_0_CONST_GUEST_PASS should be its login password.
# NOTE: for windows guest.  i m using perl script to get memory and swap.  i have scheduled a perl script in windows xp which return outout to file. and 
#       copying the output to host and then parsing the values out of it.
#---------------------------------------------------------------------------------------------------------------------
#TOTAL Server CPU
TOTAL_SERVER_CPU=600
TOTAL_SERVER_MEM="$(free -m | grep 'Mem:' | awk '{print $2}')"
TOTAL_SERVER_SWAP="$(free -m | grep 'Swap:' | awk '{print $2}')"
#Sourceforge
VM_0_CONST_CPU_MAX=100
VM_0_CONST_GUEST_USR=root
VM_0_CONST_GUEST_PASS=secu1234
#Sourceforge1
VM_1_CONST_CPU_MAX=100
VM_1_CONST_GUEST_USR=root
VM_1_CONST_GUEST_PASS=4xxPY3W3
#OpenerpTest
VM_2_CONST_CPU_MAX=200
VM_2_CONST_GUEST_USR=sodexis
VM_2_CONST_GUEST_PASS=sode1234
#OpenerpDemo
VM_3_CONST_CPU_MAX=200
VM_3_CONST_GUEST_USR=sodexis
VM_3_CONST_GUEST_PASS=sode1234
#OpenerpSodexis
VM_4_CONST_CPU_MAX=200
VM_4_CONST_GUEST_USR=sodexis
VM_4_CONST_GUEST_PASS=sode1234
#SubversionEdge
VM_5_CONST_CPU_MAX=100
VM_5_CONST_GUEST_USR=root
VM_5_CONST_GUEST_PASS=sode1234
#Below is for Accounting VM (windows)
VM_6_CONST_CPU_MAX=100
VM_6_CONST_GUEST_USR=accounting
VM_6_CONST_GUEST_PASS=account1234
#---------------------------------------------------------------------------------------------------------------------

#Below is the path to script which reside in all the Virtual Machine. This consist of free -m > Nagios_<vmname>
#The idea is to use vmware workstation, vmrun utility to runscript in guest and then copy its output to host and then parse the output. which is consider to be accurate.
FREERAM_PATH="/opt/scripts/NagiosFreeRAM.sh"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
		print_help
		exit $STATE_OK
		;;
        -v | --version)
		print_release
		exit $STATE_OK
		;;
        -j | --VM-names)
				shift
				LIST_VM=$1
				;;
        -w | --warning)
                shift
                LIST_WARNING_THRESHOLD=$1
                ;;
        -c | --critical)
                shift
                LIST_CRITICAL_THRESHOLD=$1
                ;;
        *)  echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done

wc_vals() {
if [ -z "$LIST_VM" -a -z "$LIST_WARNING_THRESHOLD" -a -z "$LIST_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Please provide options for -j (VM names), -w (warning), -c (critical) respectively."
	exit $ST_UK
elif [ ! -z "$LIST_VM" -a -z "$LIST_WARNING_THRESHOLD" -a -z "$LIST_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Please also provide options for -w (warning) and -c (critical) respectively."
        exit $ST_UK
elif [ ! -z "$LIST_VM" -a ! -z "$LIST_WARNING_THRESHOLD" -a -z "$LIST_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Please also provide options for -c (critical)."
        exit $ST_UK
fi
}


wcdiff() {

LIST=$LIST_VM
# store the vm names in array.
declare -a TAB_VM=(`echo $LIST_VM | sed 's/,/ /g'`);
TOTALVM_COUNT=${#TAB_VM[@]}

if [ -z "${#TAB_VM[@]}" ]; then
	echo "ERROR : Missing VM NAMES parameter , seperated by ,(comma)."
	exit $ST_WK
else
	VM_0=`echo ${TAB_VM[0]}`
	VM_1=`echo ${TAB_VM[1]}`
	VM_2=`echo ${TAB_VM[2]}`
	VM_3=`echo ${TAB_VM[3]}`
	VM_4=`echo ${TAB_VM[4]}`
	VM_5=`echo ${TAB_VM[5]}`
	VM_6=`echo ${TAB_VM[6]}`
fi

declare -a TAB_WARNING_THRESHOLD=(`echo $LIST_WARNING_THRESHOLD | sed 's/[-,]/ /g'`);
TOTAL_TAB_WARNING_THRESHOLD=`echo "${TOTALVM_COUNT} * 3" | bc`
if [ "${#TAB_WARNING_THRESHOLD[@]}" -ne "$TOTAL_TAB_WARNING_THRESHOLD" ]; then
	echo "ERROR : Missing $TOTALVM_COUNT parameter in Warning Threshold, seperated by ,(comma). Values in order as $LIST"
	exit $ST_WK
else  
	VM_0_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[0]}`
	VM_0_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[1]}`
	VM_0_SWAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[2]}`
	VM_1_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[3]}`
	VM_1_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[4]}`
	VM_1_SWAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[5]}`
	VM_2_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[6]}`
	VM_2_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[7]}`
	VM_2_SWAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[8]}`
	VM_3_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[9]}`
	VM_3_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[10]}`
	VM_3_SWAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[11]}`
	VM_4_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[12]}`
	VM_4_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[13]}`
	VM_4_SWAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[14]}`
	VM_5_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[15]}`
	VM_5_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[16]}`
	VM_5_SWAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[17]}`
	VM_6_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[18]}`
	VM_6_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[19]}`
	VM_6_SWAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[20]}`
fi

# List to Table for critical threshold
declare -a TAB_CRITICAL_THRESHOLD=(`echo $LIST_CRITICAL_THRESHOLD | sed 's/[-,]/ /g'`);
TOTAL_TAB_CRITICAL_THRESHOLD=`echo "${TOTALVM_COUNT} * 3" | bc`
if [ "${#TAB_CRITICAL_THRESHOLD[@]}" -ne "$TOTAL_TAB_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Missing $TOTALVM_COUNT parameter in CRITICAL Threshold, seperated by ,(comma). Eg: values in order as $LIST"
	exit $ST_WK
else 
	VM_0_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[0]}`
	VM_0_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[1]}`
	VM_0_SWAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[2]}`
	VM_1_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[3]}`
	VM_1_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[4]}`
	VM_1_SWAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[5]}`
	VM_2_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[6]}`
	VM_2_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[7]}`
	VM_2_SWAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[8]}`
	VM_3_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[9]}`
	VM_3_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[10]}`
	VM_3_SWAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[11]}`
	VM_4_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[12]}`
	VM_4_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[13]}`
	VM_4_SWAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[14]}`
	VM_5_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[15]}`
	VM_5_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[16]}`
	VM_5_SWAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[17]}`
	VM_6_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[18]}`
	VM_6_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[19]}`
	VM_6_SWAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[20]}`
fi

IVALUE=`echo "${TOTALVM_COUNT} * 3" | bc`
for (( i=0; i>="$IVALUE"; i++ ))
do
	if [[ ${TAB_WARNING_THRESHOLD[i]} -ge ${TAB_CRITICAL_THRESHOLD[i]} ]]; then
		echo "ERROR : All Warning Threshold must be lower than Critical Threshold"
		exit $ST_WK
		break
	fi
done
}


get_vals() {

#VM_0_PERF , if it is 1  then graph will be draw 1.  if it become 0. then no graph is drawn which means VM is down. 
#VM_0_DEC_CPU varible stores actual value in % which are in decimal.
#VM_0_CPU variable is to round of decimal.  which is used for comparing with warning and critical thresholds.

if [ `$VMRUN list | grep -w $VM_0 |wc -l` -eq "1" ]; then VM_0_STATE="ON";VM_0_PERF="1"; else VM_0_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_1 |wc -l` -eq "1" ]; then VM_1_STATE="ON";VM_1_PERF="1"; else VM_1_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_2 |wc -l` -eq "1" ]; then VM_2_STATE="ON";VM_2_PERF="1"; else VM_2_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_3 |wc -l` -eq "1" ]; then VM_3_STATE="ON";VM_3_PERF="1"; else VM_3_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_4 |wc -l` -eq "1" ]; then VM_4_STATE="ON";VM_4_PERF="1"; else VM_4_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_5 |wc -l` -eq "1" ]; then VM_5_STATE="ON";VM_5_PERF="1"; else VM_5_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_6 |wc -l` -eq "1" ]; then VM_6_STATE="ON";VM_6_PERF="1"; else VM_6_STATE="OFF";VM_0_PERF="0"; fi

VM_0_OUT="/tmp/Nagios-$VM_0"
VM_0_VMX="$(echo "$VM_0".vmx)"
VM_0_PATH="$($VMRUN list | grep "$VM_0_VMX")"
$VMRUN -T ws -gu $VM_0_CONST_GUEST_USR -gp $VM_0_CONST_GUEST_PASS runScriptInGuest $VM_0_PATH /bin/bash $FREERAM_PATH
$VMRUN -T ws -gu $VM_0_CONST_GUEST_USR -gp $VM_0_CONST_GUEST_PASS copyFileFromGuestToHost $VM_0_PATH $VM_0_OUT $VM_0_OUT
VM_0_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_0_VMX" | awk '{print $3}')
VM_0_CPU=`echo "(${VM_0_DEC_CPU}+0.5)/1" | bc`
VM_0_RAM="$(grep 'buffers/cache:' "$VM_0_OUT" | awk '{print $3}')"
VM_0_TOTRAM="$(grep 'Mem:' "$VM_0_OUT" | awk '{print $2}')"
VM_0_SWAP="$(grep 'Swap:' "$VM_0_OUT" | awk '{print $3}')"
VM_0_TOTSWAP="$(grep 'Swap:' "$VM_0_OUT" | awk '{print $2}')"


VM_1_OUT="/tmp/Nagios-$VM_1"
VM_1_VMX="$(echo "$VM_1".vmx)"
VM_1_PATH="$($VMRUN list | grep "$VM_1_VMX")"
$VMRUN -T ws -gu $VM_1_CONST_GUEST_USR -gp $VM_1_CONST_GUEST_PASS runScriptInGuest $VM_1_PATH /bin/bash $FREERAM_PATH
$VMRUN -T ws -gu $VM_1_CONST_GUEST_USR -gp $VM_1_CONST_GUEST_PASS copyFileFromGuestToHost $VM_1_PATH $VM_1_OUT $VM_1_OUT
VM_1_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_1_VMX" | awk '{print $3}')
VM_1_CPU=`echo "(${VM_1_DEC_CPU}+0.5)/1" | bc`
VM_1_RAM="$(grep 'buffers/cache:' "$VM_1_OUT" | awk '{print $3}')"
VM_1_TOTRAM="$(grep 'Mem:' "$VM_1_OUT" | awk '{print $2}')"
VM_1_SWAP="$(grep 'Swap:' "$VM_1_OUT" | awk '{print $3}')"
VM_1_TOTSWAP="$(grep 'Swap:' "$VM_1_OUT" | awk '{print $2}')"

VM_2_OUT="/tmp/Nagios-$VM_2"
VM_2_VMX="$(echo "$VM_2".vmx)"
VM_2_PATH="$($VMRUN list | grep "$VM_2_VMX")"
$VMRUN -T ws -gu $VM_2_CONST_GUEST_USR -gp $VM_2_CONST_GUEST_PASS runScriptInGuest $VM_2_PATH /bin/bash $FREERAM_PATH
$VMRUN -T ws -gu $VM_2_CONST_GUEST_USR -gp $VM_2_CONST_GUEST_PASS copyFileFromGuestToHost $VM_2_PATH $VM_2_OUT $VM_2_OUT
VM_2_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_2_VMX" | awk '{print $3}')
VM_2_CPU=`echo "(${VM_2_DEC_CPU}+0.5)/1" | bc`
VM_2_RAM="$(grep 'buffers/cache:' "$VM_2_OUT" | awk '{print $3}')"
VM_2_TOTRAM="$(grep 'Mem:' "$VM_2_OUT" | awk '{print $2}')"
VM_2_SWAP="$(grep 'Swap:' "$VM_2_OUT" | awk '{print $3}')"
VM_2_TOTSWAP="$(grep 'Swap:' "$VM_2_OUT" | awk '{print $2}')"

VM_3_OUT="/tmp/Nagios-$VM_3"
VM_3_VMX="$(echo "$VM_3".vmx)"
VM_3_PATH="$($VMRUN list | grep "$VM_3_VMX")"
$VMRUN -T ws -gu $VM_3_CONST_GUEST_USR -gp $VM_3_CONST_GUEST_PASS runScriptInGuest $VM_3_PATH /bin/bash $FREERAM_PATH
$VMRUN -T ws -gu $VM_3_CONST_GUEST_USR -gp $VM_3_CONST_GUEST_PASS copyFileFromGuestToHost $VM_3_PATH $VM_3_OUT $VM_3_OUT
VM_3_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_3_VMX" | awk '{print $3}')
VM_3_CPU=`echo "(${VM_3_DEC_CPU}+0.5)/1" | bc`
VM_3_RAM="$(grep 'buffers/cache:' "$VM_3_OUT" | awk '{print $3}')"
VM_3_TOTRAM="$(grep 'Mem:' "$VM_3_OUT" | awk '{print $2}')"
VM_3_SWAP="$(grep 'Swap:' "$VM_3_OUT" | awk '{print $3}')"
VM_3_TOTSWAP="$(grep 'Swap:' "$VM_3_OUT" | awk '{print $2}')"

VM_4_OUT="/tmp/Nagios-$VM_4"
VM_4_VMX="$(echo "$VM_4".vmx)"
VM_4_PATH="$($VMRUN list | grep "$VM_4_VMX")"
$VMRUN -T ws -gu $VM_4_CONST_GUEST_USR -gp $VM_4_CONST_GUEST_PASS runScriptInGuest $VM_4_PATH /bin/bash $FREERAM_PATH
$VMRUN -T ws -gu $VM_4_CONST_GUEST_USR -gp $VM_4_CONST_GUEST_PASS copyFileFromGuestToHost $VM_4_PATH $VM_4_OUT $VM_4_OUT
VM_4_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_4_VMX" | awk '{print $3}')
VM_4_CPU=`echo "(${VM_4_DEC_CPU}+0.5)/1" | bc`
VM_4_RAM="$(grep 'buffers/cache:' "$VM_4_OUT" | awk '{print $3}')"
VM_4_TOTRAM="$(grep 'Mem:' "$VM_4_OUT" | awk '{print $2}')"
VM_4_SWAP="$(grep 'Swap:' "$VM_4_OUT" | awk '{print $3}')"
VM_4_TOTSWAP="$(grep 'Swap:' "$VM_4_OUT" | awk '{print $2}')"

VM_5_OUT="/tmp/Nagios-$VM_5"
VM_5_VMX="$(echo "$VM_5".vmx)"
VM_5_PATH="$($VMRUN list | grep "$VM_5_VMX")"
$VMRUN -T ws -gu $VM_5_CONST_GUEST_USR -gp $VM_5_CONST_GUEST_PASS runScriptInGuest $VM_5_PATH /bin/bash $FREERAM_PATH
$VMRUN -T ws -gu $VM_5_CONST_GUEST_USR -gp $VM_5_CONST_GUEST_PASS copyFileFromGuestToHost $VM_5_PATH $VM_5_OUT $VM_5_OUT
VM_5_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_5_VMX" | awk '{print $3}')
VM_5_CPU=`echo "(${VM_5_DEC_CPU}+0.5)/1" | bc`
VM_5_RAM="$(grep 'buffers/cache:' "$VM_5_OUT" | awk '{print $3}')"
VM_5_TOTRAM="$(grep 'Mem:' "$VM_5_OUT" | awk '{print $2}')"
VM_5_SWAP="$(grep 'Swap:' "$VM_5_OUT" | awk '{print $3}')"
VM_5_TOTSWAP="$(grep 'Swap:' "$VM_5_OUT" | awk '{print $2}')"

#FOR Accouting_VM windows. (special parameters)
VM_6_WINOUT="C:\Nagios-${VM_6}.txt"
VM_6_OUT="/tmp/Nagios-$VM_6"
VM_6_VMX="$(echo "$VM_6".vmx)"
VM_6_PATH="$($VMRUN list | grep "$VM_6_VMX")"
$VMRUN -T ws -gu $VM_6_CONST_GUEST_USR -gp $VM_6_CONST_GUEST_PASS copyFileFromGuestToHost $VM_6_PATH $VM_6_WINOUT $VM_6_OUT
VM_6_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_6_VMX" | awk '{print $3}')
VM_6_CPU=`echo "(${VM_6_DEC_CPU}+0.5)/1" | bc`
VM_6_RAM="$(grep 'MemoryUsed:' "$VM_6_OUT" | awk '{print $2}')"   
VM_6_TOTRAM="$(grep 'MemoryTotal:' "$VM_6_OUT" | awk '{print $2}')"
VM_6_SWAP="$(grep 'SwapUsed:' "$VM_6_OUT" | awk '{print $2}')"
VM_6_TOTSWAP="$(grep 'SwapTotal:' "$VM_6_OUT" | awk '{print $2}')"

TOTAL_VM_ON=`echo "${VM_0_PERF} + ${VM_1_PERF} + ${VM_2_PERF} + ${VM_3_PERF} + ${VM_4_PERF} + ${VM_5_PERF} + ${VM_6_PERF}" | bc`
TOTAL_VM_CPU_USED=`echo "${VM_0_DEC_CPU} + ${VM_1_DEC_CPU} + ${VM_2_DEC_CPU} + ${VM_3_DEC_CPU} + ${VM_4_DEC_CPU} + ${VM_5_DEC_CPU} + ${VM_6_DEC_CPU}" | bc`
TOTAL_VM_MEM_USED=`echo "${VM_0_RAM} + ${VM_1_RAM} + ${VM_2_RAM} + ${VM_3_RAM} + ${VM_4_RAM} + ${VM_5_RAM} + ${VM_6_RAM}" | bc`
TOTAL_VM_SWAP_USED=`echo "${VM_0_SWAP} + ${VM_1_SWAP} + ${VM_2_SWAP} + ${VM_3_SWAP} + ${VM_4_SWAP} + ${VM_5_SWAP} + ${VM_6_SWAP}" | bc`
}


do_output() {
	OUTPUT="Total_VM: ${TOTAL_VM_ON}, Total_Cpu_Used: ${TOTAL_VM_CPU_USED}/${TOTAL_SERVER_CPU}%, Total_Mem_Used: ${TOTAL_VM_MEM_USED}/${TOTAL_SERVER_MEM}MB, Total_Swap_Used: ${TOTAL_VM_SWAP_USED}/${TOTAL_SERVER_SWAP}MB"
	OUTPUT0=""$VM_0": ${VM_0_STATE}, CPU: ${VM_0_DEC_CPU}/${VM_0_CONST_CPU_MAX}%, MEM: ${VM_0_RAM}/${VM_0_TOTRAM}MB, SWAP: ${VM_0_SWAP}/${VM_0_TOTSWAP}MB"
	OUTPUT1=""$VM_1": ${VM_1_STATE}, CPU: ${VM_1_DEC_CPU}/${VM_1_CONST_CPU_MAX}%, MEM: ${VM_1_RAM}/${VM_1_TOTRAM}MB, SWAP: ${VM_1_SWAP}/${VM_1_TOTSWAP}MB"
	OUTPUT2=""$VM_2": ${VM_2_STATE}, CPU: ${VM_2_DEC_CPU}/${VM_2_CONST_CPU_MAX}%, MEM: ${VM_2_RAM}/${VM_2_TOTRAM}MB, SWAP: ${VM_2_SWAP}/${VM_2_TOTSWAP}MB"
	OUTPUT3=""$VM_3": ${VM_3_STATE}, CPU: ${VM_3_DEC_CPU}/${VM_3_CONST_CPU_MAX}%, MEM: ${VM_3_RAM}/${VM_3_TOTRAM}MB, SWAP: ${VM_3_SWAP}/${VM_3_TOTSWAP}MB"
	OUTPUT4=""$VM_4": ${VM_4_STATE}, CPU: ${VM_4_DEC_CPU}/${VM_4_CONST_CPU_MAX}%, MEM: ${VM_4_RAM}/${VM_4_TOTRAM}MB, SWAP: ${VM_4_SWAP}/${VM_4_TOTSWAP}MB"
	OUTPUT5=""$VM_5": ${VM_5_STATE}, CPU: ${VM_5_DEC_CPU}/${VM_5_CONST_CPU_MAX}%, MEM: ${VM_5_RAM}/${VM_5_TOTRAM}MB, SWAP: ${VM_5_SWAP}/${VM_5_TOTSWAP}MB"
	OUTPUT6=""$VM_6": ${VM_6_STATE}, CPU: ${VM_6_DEC_CPU}/${VM_6_CONST_CPU_MAX}%, MEM: ${VM_6_RAM}/${VM_6_TOTRAM}MB, SWAP: ${VM_6_SWAP}/${VM_6_TOTSWAP}MB"
}

do_perfdata() {
	PERFDATA="'${VM_0}'=${VM_0_PERF} '${VM_0}-CPU'=${VM_0_CPU}%;${VM_0_CPU_WARNING_THRESHOLD};${VM_0_CPU_CRITICAL_THRESHOLD};0;${VM_0_CONST_CPU_MAX}; '${VM_0}-MEM'=${VM_0_RAM}MB;${VM_0_MEM_WARNING_THRESHOLD};${VM_0_MEM_CRITICAL_THRESHOLD};0;${VM_0_TOTRAM}; '${VM_0}-SWAP'=${VM_0_SWAP}MB;${VM_0_SWAP_WARNING_THRESHOLD};${VM_0_SWAP_CRITICAL_THRESHOLD};0;${VM_0_TOTSWAP}; '${VM_1}'=${VM_1_PERF} '${VM_1}-CPU'=${VM_1_CPU}%;${VM_1_CPU_WARNING_THRESHOLD};${VM_1_CPU_CRITICAL_THRESHOLD};0;${VM_1_CONST_CPU_MAX}; '${VM_1}-MEM'=${VM_1_RAM}MB;${VM_1_MEM_WARNING_THRESHOLD};${VM_1_MEM_CRITICAL_THRESHOLD};0;${VM_1_TOTRAM}; '${VM_1}-SWAP'=${VM_1_SWAP}MB;${VM_1_SWAP_WARNING_THRESHOLD};${VM_1_SWAP_CRITICAL_THRESHOLD};0;${VM_1_TOTSWAP}; '${VM_2}'=${VM_2_PERF} '${VM_2}-CPU'=${VM_2_CPU}%;${VM_2_CPU_WARNING_THRESHOLD};${VM_2_CPU_CRITICAL_THRESHOLD};0;${VM_2_CONST_CPU_MAX}; '${VM_2}-MEM'=${VM_2_RAM}MB;${VM_2_MEM_WARNING_THRESHOLD};${VM_2_MEM_CRITICAL_THRESHOLD};0;${VM_2_TOTRAM}; '${VM_2}-SWAP'=${VM_2_SWAP}MB;${VM_2_SWAP_WARNING_THRESHOLD};${VM_2_SWAP_CRITICAL_THRESHOLD};0;${VM_2_TOTSWAP}; '${VM_3}'=${VM_3_PERF} '${VM_3}-CPU'=${VM_3_CPU}%;${VM_3_CPU_WARNING_THRESHOLD};${VM_3_CPU_CRITICAL_THRESHOLD};0;${VM_3_CONST_CPU_MAX}; '${VM_3}-MEM'=${VM_3_RAM}MB;${VM_3_MEM_WARNING_THRESHOLD};${VM_3_MEM_CRITICAL_THRESHOLD};0;${VM_3_TOTRAM}; '${VM_3}-SWAP'=${VM_3_SWAP}MB;${VM_3_SWAP_WARNING_THRESHOLD};${VM_3_SWAP_CRITICAL_THRESHOLD};0;${VM_3_TOTSWAP}; '${VM_4}'=${VM_4_PERF} '${VM_4}-CPU'=${VM_4_CPU}%;${VM_4_CPU_WARNING_THRESHOLD};${VM_4_CPU_CRITICAL_THRESHOLD};0;${VM_4_CONST_CPU_MAX}; '${VM_4}-MEM'=${VM_4_RAM}MB;${VM_4_MEM_WARNING_THRESHOLD};${VM_4_MEM_CRITICAL_THRESHOLD};0;${VM_4_TOTRAM}; '${VM_4}-SWAP'=${VM_4_SWAP}MB;${VM_4_SWAP_WARNING_THRESHOLD};${VM_4_SWAP_CRITICAL_THRESHOLD};0;${VM_4_TOTSWAP}; '${VM_5}'=${VM_5_PERF} '${VM_5}-CPU'=${VM_5_CPU}%;${VM_5_CPU_WARNING_THRESHOLD};${VM_5_CPU_CRITICAL_THRESHOLD};0;${VM_5_CONST_CPU_MAX}; '${VM_5}-MEM'=${VM_5_RAM}MB;${VM_5_MEM_WARNING_THRESHOLD};${VM_5_MEM_CRITICAL_THRESHOLD};0;${VM_5_TOTRAM}; '${VM_5}-SWAP'=${VM_5_SWAP}MB;${VM_5_SWAP_WARNING_THRESHOLD};${VM_5_SWAP_CRITICAL_THRESHOLD};0;${VM_5_TOTSWAP}; '${VM_6}'=${VM_6_PERF} '${VM_6}-CPU'=${VM_6_CPU}%;${VM_6_CPU_WARNING_THRESHOLD};${VM_6_CPU_CRITICAL_THRESHOLD};0;${VM_6_CONST_CPU_MAX}; '${VM_6}-MEM'=${VM_6_RAM}MB;${VM_6_MEM_WARNING_THRESHOLD};${VM_6_MEM_CRITICAL_THRESHOLD};0;${VM_6_TOTRAM}; '${VM_6}-SWAP'=${VM_6_SWAP}MB;${VM_6_SWAP_WARNING_THRESHOLD};${VM_6_SWAP_CRITICAL_THRESHOLD};0;${VM_6_TOTSWAP};"
}

wc_vals
wcdiff
get_vals
do_output
do_perfdata

# Return
if [[ "${VM_0_PERF}" -eq "0" ]]; then 
	echo "${VM_0} STATE CRITICAL : ${OUTPUT0} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_1_PERF}" -eq "0" ]]; then 
		echo "${VM_1} STATE CRITICAL : ${OUTPUT1} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_2_PERF}" -eq "0" ]]; then 
		echo "${VM_2} STATE CRITICAL : ${OUTPUT2} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_3_PERF}" -eq "0" ]]; then 
		echo "${VM_3} STATE CRITICAL : ${OUTPUT3} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_4_PERF}" -eq "0" ]]; then 
		echo "${VM_4} STATE CRITICAL : ${OUTPUT4} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_5_PERF}" -eq "0" ]]; then 
		echo "${VM_5} STATE CRITICAL : ${OUTPUT5} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_6_PERF}" -eq "0" ]]; then 
		echo "${VM_6} STATE CRITICAL : ${OUTPUT6} | ${PERFDATA}"
		exit $ST_CR
	#--------------------------------------------------------------------------
	elif [[ "${VM_0_CPU}" -ge "${VM_0_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} CPU CRITICAL : ${OUTPUT0} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_1_CPU}" -ge "${VM_1_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} CPU CRITICAL : ${OUTPUT1} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_2_CPU}" -ge "${VM_2_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} CPU CRITICAL : ${OUTPUT2} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_3_CPU}" -ge "${VM_3_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} CPU CRITICAL : ${OUTPUT3} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_4_CPU}" -ge "${VM_4_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} CPU CRITICAL : ${OUTPUT4} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_5_CPU}" -ge "${VM_5_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} CPU CRITICAL : ${OUTPUT5} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_6_CPU}" -ge "${VM_6_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} CPU CRITICAL : ${OUTPUT6} | ${PERFDATA}"
		exit $ST_CR
	#---------------------------------------------------------------------------
	# Commented the MEM alert because i consider it would be good to monitor the swap usage of VM.  because that makes host to start kswap0 process which uses high priority and high CPU stopping anyother process in its way.
	#----------------------------------------------------------------------------
	#elif [[ "${VM_0_MEM}" -ge "${VM_0_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_0} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_CR
	# elif [[ "${VM_1_MEM}" -ge "${VM_1_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_1} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_CR
	# elif [[ "${VM_2_MEM}" -ge "${VM_2_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_2} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_CR
	# elif [[ "${VM_3_MEM}" -ge "${VM_3_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_3} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_CR
	# elif [[ "${VM_4_MEM}" -ge "${VM_4_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_4} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_CR
	# elif [[ "${VM_5_MEM}" -ge "${VM_5_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_5} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_CR
	# elif [[ "${VM_6_MEM}" -ge "${VM_6_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_6} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_CR
	#----------------------------------------------------------------------------
	elif [[ "${VM_0_SWAP}" -ge "${VM_0_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} SWAP CRITICAL : ${OUTPUT0} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_1_SWAP}" -ge "${VM_1_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} SWAP CRITICAL : ${OUTPUT1} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_2_SWAP}" -ge "${VM_2_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} SWAP CRITICAL : ${OUTPUT2} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_3_SWAP}" -ge "${VM_3_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} SWAP CRITICAL : ${OUTPUT3} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_4_SWAP}" -ge "${VM_4_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} SWAP CRITICAL : ${OUTPUT4} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_5_SWAP}" -ge "${VM_5_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} SWAP CRITICAL : ${OUTPUT5} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_6_SWAP}" -ge "${VM_6_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} SWAP CRITICAL : ${OUTPUT6} | ${PERFDATA}"
		exit $ST_CR
	#--------------------------------------------------------------------------------------------------------------------------------
	elif [[ "${VM_0_CPU}" -ge "${VM_0_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_0_CPU}" -lt "${VM_0_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} CPU WARNING : ${OUTPUT0} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_1_CPU}" -ge "${VM_1_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_1_CPU}" -lt "${VM_1_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} CPU WARNING : ${OUTPUT1} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_2_CPU}" -ge "${VM_2_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_2_CPU}" -lt "${VM_2_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} CPU WARNING : ${OUTPUT2} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_3_CPU}" -ge "${VM_3_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_3_CPU}" -lt "${VM_3_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} CPU WARNING : ${OUTPUT3} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_4_CPU}" -ge "${VM_4_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_4_CPU}" -lt "${VM_4_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} CPU WARNING : ${OUTPUT4} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_5_CPU}" -ge "${VM_5_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_5_CPU}" -lt "${VM_5_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} CPU WARNING : ${OUTPUT5} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_6_CPU}" -ge "${VM_6_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_6_CPU}" -lt "${VM_6_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} CPU WARNING : ${OUTPUT6} | ${PERFDATA}"
		exit $ST_WR
	#====================================================================================================================================
	# elif [[ "${VM_0_MEM}" -ge "${VM_0_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_0_MEM}" -lt "${VM_0_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_0} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_WR
	# elif [[ "${VM_1_MEM}" -ge "${VM_1_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_1_MEM}" -lt "${VM_1_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_1} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_WR
	# elif [[ "${VM_2_MEM}" -ge "${VM_2_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_2_MEM}" -lt "${VM_2_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_2} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_WR
	# elif [[ "${VM_3_MEM}" -ge "${VM_3_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_3_MEM}" -lt "${VM_3_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_3} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_WR
	# elif [[ "${VM_4_MEM}" -ge "${VM_4_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_4_MEM}" -lt "${VM_4_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_4} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_WR
	# elif [[ "${VM_5_MEM}" -ge "${VM_5_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_5_MEM}" -lt "${VM_5_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_5} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_WR
	# elif [[ "${VM_6_MEM}" -ge "${VM_6_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_6_MEM}" -lt "${VM_6_MEM_CRITICAL_THRESHOLD}" ]]; then
	# 	echo "${VM_6} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
	# 	exit $ST_WR
	#======================================================================================================================================
	elif [[ "${VM_0_SWAP}" -ge "${VM_0_SWAP_WARNING_THRESHOLD}" ]] && [[ "${VM_0_SWAP}" -lt "${VM_0_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} SWAP WARNING : ${OUTPUT0} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_1_SWAP}" -ge "${VM_1_SWAP_WARNING_THRESHOLD}" ]] && [[ "${VM_1_SWAP}" -lt "${VM_1_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} SWAP WARNING : ${OUTPUT1} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_2_SWAP}" -ge "${VM_2_SWAP_WARNING_THRESHOLD}" ]] && [[ "${VM_2_SWAP}" -lt "${VM_2_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} SWAP WARNING : ${OUTPUT2} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_3_SWAP}" -ge "${VM_3_SWAP_WARNING_THRESHOLD}" ]] && [[ "${VM_3_SWAP}" -lt "${VM_3_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} SWAP WARNING : ${OUTPUT3} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_4_SWAP}" -ge "${VM_4_SWAP_WARNING_THRESHOLD}" ]] && [[ "${VM_4_SWAP}" -lt "${VM_4_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} SWAP WARNING : ${OUTPUT4} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_5_SWAP}" -ge "${VM_5_SWAP_WARNING_THRESHOLD}" ]] && [[ "${VM_5_SWAP}" -lt "${VM_5_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} SWAP WARNING : ${OUTPUT5} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_6_SWAP}" -ge "${VM_6_SWAP_WARNING_THRESHOLD}" ]] && [[ "${VM_6_SWAP}" -lt "${VM_6_SWAP_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} SWAP WARNING : ${OUTPUT6} | ${PERFDATA}"
		exit $ST_WR
else
	echo "OK : ${OUTPUT} | ${PERFDATA}"
	exit $ST_OK
fi
