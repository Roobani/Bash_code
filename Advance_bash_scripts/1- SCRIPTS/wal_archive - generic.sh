#!/bin/bash
# replace archive_command in postgresql.conf in master.
# archive_command = 'test ! -f /pg_archive/jodee/%f && cp %p /pg_archive/jodee/%f && /usr/bin/rsync -W -az %p postgres@128.133.97.73:/pg_archive/jodee/%f'


ARCHIVE_DIR="/pg_archive/sciencefirst"
ARCHIVE_TO_KEEP="3"   
DNOW=`date +%u`
hour=$(date +%H) 


#Do the cleanup if the day is Monday or Thursday and time is between 11 p.m. UTC and 22 hrs UTC
if [ "$DNOW" -eq "1" -o "$DNOW" -eq "4" -a "$hour" -ge 11 -a "$hour" -lt 22 ]; then
  find "${ARCHIVE_DIR}"/ -type f -mtime +"${ARCHIVE_TO_KEEP}" -exec rm -f {} +
fi
