#!/bin/ksh
#
PROGNAME=`basename $0`
VERSION="Version 1.0,"
AUTHOR="John Britto"

JDKPATH=`find /usr/java -type d -name 'jdk1.*'`
export JAVA_HOME=$JDKPATH

#
ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin to check a JVM process internal metrics"
    echo ""
    echo "USAGE: $PROGNAME -j [Jvm name] -w [1000,50] -c [2000,100]"
    echo ""
    echo "To find running JVM name, use "jps -l" to display process name."
    echo "The warning and critical threashold must be in a format [Heap,CPU]. Without []"
    echo "The Heap warning and critical threashold will be consider as in MB (Mega Byte)"
    echo "The CPU warning and critical threashold will be consider as in %"
    echo ""
    echo "Example: $PROGNAME -j org.jboss.Main -w 1000,50 -c 2000,100"
    echo ""
    echo "Options:"
    echo "  -j/--process)"
    echo "      -j  the java app (see jps) process to monitor "
    echo "     then \"greped\"."
    echo "  -w/--warning)"
    echo ""
    echo "  -c/--critical)"
    exit $ST_UK
}

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
        -j | --process)
		shift
		PROCESS=$1
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
if [ -z "$PROCESS" -a -z "$LIST_WARNING_THRESHOLD" -a -z "$LIST_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Please provide options for -j (jvm process), -w (warning), -c (critical) respectively."
	exit $ST_UK
elif [ ! -z "$PROCESS" -a -z "$LIST_WARNING_THRESHOLD" -a -z "$LIST_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Please also provide options for -w (warning) and -c (critical) respectively."
        exit $ST_UK
elif [ ! -z "$PROCESS" -a ! -z "$LIST_WARNING_THRESHOLD" -a -z "$LIST_CRITICAL_THRESHOLD" ]; then
	echo "ERROR : Please also provide options for -c (critical)."
        exit $ST_UK
fi
}

wcdiff() {
set +A TAB_WARNING_THRESHOLD `echo $LIST_WARNING_THRESHOLD | sed 's/,/ /g'`
if [ "${#TAB_WARNING_THRESHOLD[@]}" -ne "3" ]; then
	echo "ERROR : Missing 3 parameter in Warning Threshold, seperated by ,(comma). Values in order as cpu(%),heap(MB),nonheap(MB)"
	exit $ST_WK
else  
	CPU_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[0]}`
	HEAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[1]}`
	NONHEAP_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[2]}`
	DEADLOCK_WARNING_THRESHOLD=0 
fi

# List to Table for critical threshold
set +A TAB_CRITICAL_THRESHOLD `echo $LIST_CRITICAL_THRESHOLD | sed 's/,/ /g'`
if [ "${#TAB_CRITICAL_THRESHOLD[@]}" -ne "3" ]; then
	echo "ERROR : Missing 3 parameter in CRITICAL Threshold, seperated by ,(comma). Eg: values in order as cpu(%),heap(MB),nonheap(MB)"
	exit $ST_WK
else 
	CPU_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[0]}`
	HEAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[1]}`
	NONHEAP_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[2]}`
	DEADLOCK_CRITICAL_THRESHOLD=1
fi

if [ ${TAB_WARNING_THRESHOLD[0]} -ge ${TAB_CRITICAL_THRESHOLD[0]} -o ${TAB_WARNING_THRESHOLD[1]} -ge ${TAB_CRITICAL_THRESHOLD[1]} -o ${TAB_WARNING_THRESHOLD[2]} -ge ${TAB_CRITICAL_THRESHOLD[2]} ]; then
	echo "ERROR : All Warning Threshold must be lower than Critical Threshold "
	exit $ST_WK
fi 
}

get_vals() {
DIR=/usr/local/nagios/libexec
cd $DIR    	
OLDIFS=$IFS
IFS='\n'
tmp_output=`/usr/local/nagios/libexec/jvmtop.sh --once | grep -e "$PROCESS"`
IFS=$OLDIFS
	if [ -z "$tmp_output" ]
        then
        	echo "CRITICAL - JVM Process to monitor is not running!"
        exit $ST_CR
    	fi
PID=`echo ${tmp_output} | awk '{print $1}'`
HPCUR=`echo ${tmp_output} | awk '{print $3}' | sed 's/.$//'`
HPMAX=`echo ${tmp_output} | awk '{print $4}' | sed 's/.$//'`
NHCUR=`echo ${tmp_output} | awk '{print $5}' | sed 's/.$//'`
NHMAX=`echo ${tmp_output} | awk '{print $6}' | sed 's/.$//'`
CPU=`echo ${tmp_output} | awk '{print $7}' | sed 's/.$//' | cut -d . -f 1`
GC=`echo ${tmp_output} | awk '{print $8}' | sed 's/.$//' | cut -d . -f 1`
THREAD=`echo ${tmp_output} | awk '{print $11}'`
DEAD=`echo ${tmp_output} | awk '{print $12}'`
	if [ -z "$HPCUR" ]; then
	echo "CRITICAL - jvmtop doesn't output values"
	exit $ST_CR
	fi
	if [ -z "$DEAD" ]
	then
		DEADLOCK=0
	else
		DEADLOCK=1
	fi
}

do_output() {
	OUTPUT="Jvm: ${PROCESS}, Pid: ${PID}, CPU: ${CPU}%, Heap: ${HPCUR}/${HPMAX}MB, Non-Heap: ${NHCUR}/${NHMAX}MB, GC: ${GC}%, Threads: ${THREAD}, Deadlock: ${DEADLOCK}"
}

do_perfdata() {
	PERFDATA="'PID'=${PID} 'CPU'=${CPU}%;${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0; 'Heap Memory'=${HPCUR}MB;${TAB_WARNING_THRESHOLD[1]};${TAB_CRITICAL_THRESHOLD[1]};0; 'Non-Heap Memory'=${NHCUR}MB;${TAB_WARNING_THRESHOLD[2]};${TAB_CRITICAL_THRESHOLD[2]};0; 'Thread'=${THREAD} 'GC Runs'=${GC}% 'Deadlock'=${DEADLOCK};${DEADLOCK_WARNING_THRESHOLD};${DEADLOCK_CRITICAL_THRESHOLD};0;"
}

wc_vals
wcdiff
get_vals
do_output
do_perfdata

# Return
if [ ${CPU} -ge $CPU_CRITICAL_THRESHOLD ]; then
	echo "JAVA CPU CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [ ${HPCUR} -ge $HEAP_CRITICAL_THRESHOLD ]; then
		echo "JAVA HEAP CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [ ${NHCUR} -ge $NONHEAP_CRITICAL_THRESHOLD ]; then
        echo "JAVA NON-HEAP CRITICAL : ${OUTPUT} | ${PERFDATA}"
        exit $ST_CR
	elif [ ${DEADLOCK} -ge $DEADLOCK_CRITICAL_THRESHOLD ]; then
		echo "JAVA DEADLOCK CRITICAL : ${OUTPUT} | ${PERFDATA}"
		exit $ST_CR
	elif [ ${CPU} -ge $CPU_WARNING_THRESHOLD ] && [ ${CPU} -lt $CPU_CRITICAL_THRESHOLD ]; then
		echo "JAVA CPU WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR	
	elif [ ${HPCUR} -ge $HEAP_WARNING_THRESHOLD ] && [ ${HPCUR} -lt $HEAP_CRITICAL_THRESHOLD ]; then
		echo "JAVA HEAP WARNING : ${OUTPUT} | ${PERFDATA}"
		exit $ST_WR
	elif [ ${NHCUR} -ge $NONHEAP_WARNING_THRESHOLD ] && [ ${NHCUR} -lt $NONHEAP_CRITICAL_THRESHOLD ]; then
        echo "JAVA NON-HEAP WARNING : ${OUTPUT} | ${PERFDATA}"
        exit $ST_WR	
else
	echo "OK : ${OUTPUT} | ${PERFDATA}"
	exit $ST_OK
fi
