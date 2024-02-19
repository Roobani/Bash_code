#!/bin/bash

# Author: John Britto
# Created date: sun, 17 Nov 2013.

REPOS=$1
REV=$2
SENDTO=$3
SENDFROM=SubversionEdge@localhost.sodexis.com
REPLYTO=john@sodexis.com
svnlook="/opt/csvn/bin/svnlook"
REPOSIT=`basename $REPOS`

LIMITDIFF=200
CHANGELOG=`$svnlook log -r $REV $REPOS`
AUTHOR=`$svnlook author -r $REV $REPOS`
CHANGED=`$svnlook changed -r $REV $REPOS`
DIFF=`$svnlook diff -r $REV $REPOS | head --lines=$LIMITDIFF`
DATE=`date`
TMPFILE=/tmp/svn$REV-$RANDOM.message
TMPFILE1=/tmp/svn$REV-$RANDOM.message

SUBJECT="SVNCommit by ($AUTHOR), $REPOSIT at [$REV]"
echo "==================== SVN Commit Notification ====================
Repository : $REPOSIT
Revision    : $REV
Author      : $AUTHOR
Date         : $DATE

-----------------------------------------------------------------
Log Message:
-----------------------------------------------------------------
$CHANGELOG

-----------------------------------------------------------------
Changes:
-----------------------------------------------------------------
$CHANGED

-----------------------------------------------------------------
Diff: (only first $LIMITDIFF lines shown)
-----------------------------------------------------------------
$DIFF

===================================================================
" > $TMPFILE

# To remove ^M placed after end of each new line in diff
tr -d '\015' < $TMPFILE > $TMPFILE1

# Send email
cat -v $TMPFILE1 | mail -s "$SUBJECT" -r "$SENDFROM" -Sreplyto="$REPLYTO" "$SENDTO"

# Cleanup
rm $TMPFILE
rm $TMPFILE1