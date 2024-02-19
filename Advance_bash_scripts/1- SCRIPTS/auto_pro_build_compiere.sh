#!/bin/sh

URL="http://sourceforge.sodexis.com/svn/repos/blueprintsvn/trunk
PASS="john1234"
#DIR="/var/app/compiere/blueprint/blueprintsvn/trunk
SVN="$(which svn)"
SVN_REVISION=`svn info--username john --password john1234 --non-interactive --no-auth-cache https://sourceforge.sodexis.com/svn/repos/blueprintsvn/trunk |grep '^Revision:' | sed -e 's/^Revision: //'`
echo $SVN_REVISION

exit 1
