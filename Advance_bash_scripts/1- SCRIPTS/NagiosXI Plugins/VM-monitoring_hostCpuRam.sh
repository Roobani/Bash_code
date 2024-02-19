#!/bin/bash

#COUNTER=1

# function cpu_mem {
# echo VM: $VM
# CPU=$(ps aux |grep -v grep | grep $VM |awk '{print $3}')
# MEM=$(ps aux |grep -v grep | grep $VM |awk '{print $4}')
# echo cpu:$CPU
# echo mem:$MEM
# }

# ## Run Command to find list of VM names:
# ## this will only be the name of the vm, no path and no .vmx
#         VMLIST=`vmrun list | grep '/' | cut -d'/' -f6 | cut -d'.' -f1`
#         for VM in ${VMLIST}
#         do
#         sleep 1
#         cpu_mem
#         ((COUNTER++))
#         done
# exit 1

VMRUN="$(which vmrun)"

#---------------------------------------------------------------------------------------------------------------------
# CHANGE the below values with respect to order of VM names given in -j argument.  
# If Sourceforge_VM is given 1st in order under -J , then VM_0_CONST_CPU_MAX and VM_0_CONST_MEM_MAX
# should be set in % of MAX CPU and MAX RAM allocated in the virtual machine. This is needed for graph to plot MAX .
VM_0_CONST_CPU_MAX=100
VM_0_CONST_MEM_MAX=100
VM_1_CONST_CPU_MAX=100
VM_1_CONST_MEM_MAX=100
VM_2_CONST_CPU_MAX=100
VM_2_CONST_MEM_MAX=100
VM_3_CONST_CPU_MAX=100
VM_3_CONST_MEM_MAX=100
VM_4_CONST_CPU_MAX=100
VM_4_CONST_MEM_MAX=100
VM_5_CONST_CPU_MAX=100
VM_5_CONST_MEM_MAX=100
VM_6_CONST_CPU_MAX=100
VM_6_CONST_MEM_MAX=100
VM_7_CONST_CPU_MAX=100
VM_7_CONST_MEM_MAX=100

#---------------------------------------------------------------------------------------------------------------------

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
	VM_7=`echo ${TAB_VM[7]}`
fi

declare -a TAB_WARNING_THRESHOLD=(`echo $LIST_WARNING_THRESHOLD | sed 's/[-,]/ /g'`);
TOTAL_TAB_WARNING_THRESHOLD=`echo "${TOTALVM_COUNT} * 2" | bc`
if [ "${#TAB_WARNING_THRESHOLD[@]}" -ne "$TOTAL_TAB_WARNING_THRESHOLD" ]; then
	echo "ERROR : Missing $TOTALVM_COUNT parameter in Warning Threshold, seperated by ,(comma). Values in order as $LIST"
	exit $ST_WK
else  
	VM_0_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[0]}`
	VM_0_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[1]}`
	VM_1_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[2]}`
	VM_1_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[3]}`
	VM_2_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[4]}`
	VM_2_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[5]}`
	VM_3_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[6]}`
	VM_3_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[7]}`
	VM_4_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[8]}`
	VM_4_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[9]}`
	VM_5_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[10]}`
	VM_5_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[11]}`
	VM_6_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[12]}`
	VM_6_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[13]}`
	VM_7_CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[14]}`
	VM_7_MEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[15]}`
fi

# List to Table for critical threshold
declare -a TAB_CRITICAL_THRESHOLD=(`echo $LIST_CRITICAL_THRESHOLD | sed 's/[-,]/ /g'`);
TOTAL_TAB_CRITICAL_THRESHOLD=`echo "${TOTALVM_COUNT} * 2" | bc`
if [ "${#TAB_CRITICAL_THRESHOLD[@]}" -ne "$TOTAL_TAB_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Missing $TOTALVM_COUNT parameter in CRITICAL Threshold, seperated by ,(comma). Eg: values in order as $LIST"
	exit $ST_WK
else 
	VM_0_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[0]}`
	VM_0_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[1]}`
	VM_1_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[2]}`
	VM_1_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[3]}`
	VM_2_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[4]}`
	VM_2_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[5]}`
	VM_3_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[6]}`
	VM_3_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[7]}`
	VM_4_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[8]}`
	VM_4_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[9]}`
	VM_5_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[10]}`
	VM_5_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[11]}`
	VM_6_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[12]}`
	VM_6_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[13]}`
	VM_7_CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[14]}`
	VM_7_MEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[15]}`
fi

IVALUE=`echo "${TOTALVM_COUNT} * 2 - 1" | bc`
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

#VM_0_PERF , if it is 1  then graph will be draw 1.  if it become 0. then no graph is drawn which means VM is down.3 
#VM_0_DEC_CPU varible stores actual value in % which are in decimal.
#VM_0_CPU variable is to round of decimal.  which is used for comparing with warning and critical thresholds.

if [ `$VMRUN list | grep -w $VM_0 |wc -l` -eq "1" ]; then VM_0_STATE="ON";VM_0_PERF="1"; else VM_0_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_1 |wc -l` -eq "1" ]; then VM_1_STATE="ON";VM_1_PERF="1"; else VM_1_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_2 |wc -l` -eq "1" ]; then VM_2_STATE="ON";VM_2_PERF="1"; else VM_2_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_3 |wc -l` -eq "1" ]; then VM_3_STATE="ON";VM_3_PERF="1"; else VM_3_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_4 |wc -l` -eq "1" ]; then VM_4_STATE="ON";VM_4_PERF="1"; else VM_4_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_5 |wc -l` -eq "1" ]; then VM_5_STATE="ON";VM_5_PERF="1"; else VM_5_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_6 |wc -l` -eq "1" ]; then VM_6_STATE="ON";VM_6_PERF="1"; else VM_6_STATE="OFF";VM_0_PERF="0"; fi
if [ `$VMRUN list | grep -w $VM_7 |wc -l` -eq "1" ]; then VM_7_STATE="ON";VM_7_PERF="1"; else VM_7_STATE="OFF";VM_0_PERF="0"; fi

VM_0_VMX="$(echo "$VM_0".vmx)"
VM_0_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_0_VMX" | awk '{print $3}')
VM_0_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_0_VMX" | awk '{print $4}')
VM_0_CPU=`echo "(${VM_0_DEC_CPU}+0.5)/1" | bc`
VM_0_MEM=`echo "(${VM_0_DEC_MEM}+0.5)/1" | bc`
VM_1_VMX="$(echo "$VM_1".vmx)"
VM_1_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_1_VMX" | awk '{print $3}')
VM_1_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_1_VMX" | awk '{print $4}')
VM_1_CPU=`echo "(${VM_1_DEC_CPU}+0.5)/1" | bc`
VM_1_MEM=`echo "(${VM_1_DEC_MEM}+0.5)/1" | bc`
VM_2_VMX="$(echo "$VM_2".vmx)"
VM_2_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_2_VMX" | awk '{print $3}')
VM_2_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_2_VMX" | awk '{print $4}')
VM_2_CPU=`echo "(${VM_2_DEC_CPU}+0.5)/1" | bc`
VM_2_MEM=`echo "(${VM_2_DEC_MEM}+0.5)/1" | bc`
VM_3_VMX="$(echo "$VM_3".vmx)"
VM_3_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_3_VMX" | awk '{print $3}')
VM_3_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_3_VMX" | awk '{print $4}')
VM_3_CPU=`echo "(${VM_3_DEC_CPU}+0.5)/1" | bc`
VM_3_MEM=`echo "(${VM_3_DEC_MEM}+0.5)/1" | bc`
VM_4_VMX="$(echo "$VM_4".vmx)"
VM_4_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_4_VMX" | awk '{print $3}')
VM_4_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_4_VMX" | awk '{print $4}')
VM_4_CPU=`echo "(${VM_4_DEC_CPU}+0.5)/1" | bc`
VM_4_MEM=`echo "(${VM_4_DEC_MEM}+0.5)/1" | bc`
VM_5_VMX="$(echo "$VM_5".vmx)"
VM_5_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_5_VMX" | awk '{print $3}')
VM_5_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_5_VMX" | awk '{print $4}')
VM_5_CPU=`echo "(${VM_5_DEC_CPU}+0.5)/1" | bc`
VM_5_MEM=`echo "(${VM_5_DEC_MEM}+0.5)/1" | bc`
VM_6_VMX="$(echo "$VM_6".vmx)"
VM_6_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_6_VMX" | awk '{print $3}')
VM_6_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_6_VMX" | awk '{print $4}')
VM_6_CPU=`echo "(${VM_6_DEC_CPU}+0.5)/1" | bc`
VM_6_MEM=`echo "(${VM_6_DEC_MEM}+0.5)/1" | bc`
VM_7_VMX="$(echo "$VM_7".vmx)"
VM_7_DEC_CPU=$(ps aux | grep -v grep | grep "$VM_7_VMX" | awk '{print $3}')
VM_7_DEC_MEM=$(ps aux | grep -v grep | grep "$VM_7_VMX" | awk '{print $4}')
VM_7_CPU=`echo "(${VM_7_DEC_CPU}+0.5)/1" | bc`
VM_7_MEM=`echo "(${VM_7_DEC_MEM}+0.5)/1" | bc`
}


do_output() {
	OUTPUT=""$VM_0": ${VM_0_STATE}, CPU: ${VM_0_DEC_CPU}/${VM_0_CONST_CPU_MAX}%, MEM: ${VM_0_DEC_MEM}/${VM_0_CONST_MEM_MAX}%\n \
			"$VM_1": ${VM_1_STATE}, CPU: ${VM_1_DEC_CPU}/${VM_1_CONST_CPU_MAX}%, MEM: ${VM_1_DEC_MEM}/${VM_1_CONST_MEM_MAX}%\n \
			"$VM_2": ${VM_2_STATE}, CPU: ${VM_2_DEC_CPU}/${VM_2_CONST_CPU_MAX}%, MEM: ${VM_2_DEC_MEM}/${VM_2_CONST_MEM_MAX}%\n \
			"$VM_3": ${VM_3_STATE}, CPU: ${VM_3_DEC_CPU}/${VM_3_CONST_CPU_MAX}%, MEM: ${VM_3_DEC_MEM}/${VM_3_CONST_MEM_MAX}%\n \
			"$VM_4": ${VM_4_STATE}, CPU: ${VM_4_DEC_CPU}/${VM_4_CONST_CPU_MAX}%, MEM: ${VM_4_DEC_MEM}/${VM_4_CONST_MEM_MAX}%\n \
			"$VM_5": ${VM_5_STATE}, CPU: ${VM_5_DEC_CPU}/${VM_5_CONST_CPU_MAX}%, MEM: ${VM_5_DEC_MEM}/${VM_5_CONST_MEM_MAX}%\n \
			"$VM_6": ${VM_6_STATE}, CPU: ${VM_6_DEC_CPU}/${VM_6_CONST_CPU_MAX}%, MEM: ${VM_6_DEC_MEM}/${VM_6_CONST_MEM_MAX}%\n \
			"$VM_7": ${VM_7_STATE}, CPU: ${VM_7_DEC_CPU}/${VM_7_CONST_CPU_MAX}%, MEM: ${VM_7_DEC_MEM}/${VM_7_CONST_MEM_MAX}%"
}

do_perfdata() {
	PERFDATA="'${VM_0}'=${VM_0_PERF} '${VM_0}-CPU'=${VM_0_CPU}%;${VM_0_CPU_WARNING_THRESHOLD};${VM_0_CPU_CRITICAL_THRESHOLD};0; '${VM_0}-MEM'=${VM_0_MEM}%;${VM_0_MEM_WARNING_THRESHOLD};${VM_0_MEM_CRITICAL_THRESHOLD};0; \
			  '${VM_1}'=${VM_1_PERF} '${VM_1}-CPU'=${VM_1_CPU}%;${VM_1_CPU_WARNING_THRESHOLD};${VM_1_CPU_CRITICAL_THRESHOLD};0; '${VM_1}-MEM'=${VM_1_MEM}%;${VM_1_MEM_WARNING_THRESHOLD};${VM_1_MEM_CRITICAL_THRESHOLD};0; \
			  '${VM_2}'=${VM_2_PERF} '${VM_2}-CPU'=${VM_2_CPU}%;${VM_2_CPU_WARNING_THRESHOLD};${VM_2_CPU_CRITICAL_THRESHOLD};0; '${VM_2}-MEM'=${VM_2_MEM}%;${VM_2_MEM_WARNING_THRESHOLD};${VM_2_MEM_CRITICAL_THRESHOLD};0; \
			  '${VM_3}'=${VM_3_PERF} '${VM_3}-CPU'=${VM_3_CPU}%;${VM_3_CPU_WARNING_THRESHOLD};${VM_3_CPU_CRITICAL_THRESHOLD};0; '${VM_3}-MEM'=${VM_3_MEM}%;${VM_3_MEM_WARNING_THRESHOLD};${VM_3_MEM_CRITICAL_THRESHOLD};0; \
			  '${VM_4}'=${VM_4_PERF} '${VM_4}-CPU'=${VM_4_CPU}%;${VM_4_CPU_WARNING_THRESHOLD};${VM_4_CPU_CRITICAL_THRESHOLD};0; '${VM_4}-MEM'=${VM_4_MEM}%;${VM_4_MEM_WARNING_THRESHOLD};${VM_4_MEM_CRITICAL_THRESHOLD};0; \
			  '${VM_5}'=${VM_5_PERF} '${VM_5}-CPU'=${VM_5_CPU}%;${VM_5_CPU_WARNING_THRESHOLD};${VM_5_CPU_CRITICAL_THRESHOLD};0; '${VM_5}-MEM'=${VM_5_MEM}%;${VM_5_MEM_WARNING_THRESHOLD};${VM_5_MEM_CRITICAL_THRESHOLD};0; \
			  '${VM_6}'=${VM_6_PERF} '${VM_6}-CPU'=${VM_6_CPU}%;${VM_6_CPU_WARNING_THRESHOLD};${VM_6_CPU_CRITICAL_THRESHOLD};0; '${VM_6}-MEM'=${VM_6_MEM}%;${VM_6_MEM_WARNING_THRESHOLD};${VM_6_MEM_CRITICAL_THRESHOLD};0; \
			  '${VM_7}'=${VM_7_PERF} '${VM_7}-CPU'=${VM_7_CPU}%;${VM_7_CPU_WARNING_THRESHOLD};${VM_7_CPU_CRITICAL_THRESHOLD};0; '${VM_7}-MEM'=${VM_7_MEM}%;${VM_7_MEM_WARNING_THRESHOLD};${VM_7_MEM_CRITICAL_THRESHOLD};0;"
}

wc_vals
wcdiff
get_vals
do_output
do_perfdata

# Return
if [[ "${VM_0_PERF}" -eq "0" ]]; then 
	echo "${VM_0} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_1_PERF}" -eq "0" ]]; then 
		echo "${VM_1} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_2_PERF}" -eq "0" ]]; then 
		echo "${VM_2} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_3_PERF}" -eq "0" ]]; then 
		echo "${VM_3} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_4_PERF}" -eq "0" ]]; then 
		echo "${VM_4} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_5_PERF}" -eq "0" ]]; then 
		echo "${VM_5} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_6_PERF}" -eq "0" ]]; then 
		echo "${VM_6} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_7_PERF}" -eq "0" ]]; then 
		echo "${VM_7} STATE CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_0_CPU}" -ge "${VM_0_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_1_CPU}" -ge "${VM_1_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_2_CPU}" -ge "${VM_2_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_3_CPU}" -ge "${VM_3_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_4_CPU}" -ge "${VM_4_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_5_CPU}" -ge "${VM_5_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_6_CPU}" -ge "${VM_6_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_7_CPU}" -ge "${VM_7_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_7} CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR	
	elif [[ "${VM_0_MEM}" -ge "${VM_0_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_1_MEM}" -ge "${VM_1_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_2_MEM}" -ge "${VM_2_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_3_MEM}" -ge "${VM_3_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_4_MEM}" -ge "${VM_4_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_5_MEM}" -ge "${VM_5_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_6_MEM}" -ge "${VM_6_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_7_MEM}" -ge "${VM_7_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_7} MEM CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [[ "${VM_0_CPU}" -ge "${VM_0_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_0_CPU}" -lt "${VM_0_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_1_CPU}" -ge "${VM_1_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_1_CPU}" -lt "${VM_1_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_2_CPU}" -ge "${VM_2_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_2_CPU}" -lt "${VM_2_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_3_CPU}" -ge "${VM_3_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_3_CPU}" -lt "${VM_3_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_4_CPU}" -ge "${VM_4_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_4_CPU}" -lt "${VM_4_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_5_CPU}" -ge "${VM_5_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_5_CPU}" -lt "${VM_5_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_6_CPU}" -ge "${VM_6_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_6_CPU}" -lt "${VM_6_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_7_CPU}" -ge "${VM_7_CPU_WARNING_THRESHOLD}" ]] && [[ "${VM_7_CPU}" -lt "${VM_7_CPU_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_7} CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_0_MEM}" -ge "${VM_0_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_0_MEM}" -lt "${VM_0_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_0} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_1_MEM}" -ge "${VM_1_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_1_MEM}" -lt "${VM_1_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_1} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_2_MEM}" -ge "${VM_2_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_2_MEM}" -lt "${VM_2_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_2} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_3_MEM}" -ge "${VM_3_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_3_MEM}" -lt "${VM_3_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_3} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_4_MEM}" -ge "${VM_4_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_4_MEM}" -lt "${VM_4_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_4} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_5_MEM}" -ge "${VM_5_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_5_MEM}" -lt "${VM_5_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_5} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_6_MEM}" -ge "${VM_6_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_6_MEM}" -lt "${VM_6_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_6} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [[ "${VM_7_MEM}" -ge "${VM_7_MEM_WARNING_THRESHOLD}" ]] && [[ "${VM_7_MEM}" -lt "${VM_7_MEM_CRITICAL_THRESHOLD}" ]]; then
		echo "${VM_7} MEM WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
else
	echo "OK : ${OUTPUT} | ${PERFDATA}"
	exit $ST_OK
fi
