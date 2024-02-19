#!/bin/bash
#Usage: ./script.sh <input_file> <search month> <search year>
#P.S: The Month and Year needs to be exact format of datestamp appear in the input file.

INPUT=$1
MONTH=$2
YEAR=$3
OUT_DIR=$4
OUT_PREFIX="odoo-server"
OUT_SUFFIX=".log"

#Check if the MONTH format is string or given as integer.
if [[ -n ${MONTH//[0-9]/} ]]; then
	read mon <<< "$MONTH"
	OUT_MONTH=`date -d "$mon 1" "+%m"`
else
	OUT_MONTH="${MONTH}"
fi

for d in `seq -w 01 31`; do
d1=`expr $d + 1`
if [ "$d1" -lt "32" ]; then
    sed -n "/${YEAR}-${MONTH}-${d}/,/${YEAR}-${MONTH}-${d1}/p; /${YEAR}-${MONTH}-${d1}/q" $INPUT > ${OUT_DIR}/${OUT_PREFIX}-${YEAR}-${OUT_MONTH}-${d}${OUT_SUFFIX}
fi
done