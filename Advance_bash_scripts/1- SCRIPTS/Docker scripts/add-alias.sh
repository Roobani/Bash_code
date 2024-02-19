#!/bin/bash
FILE="/opt/support_files/scripts/odoo-alias.sh"
if [ ! -f $FILE ]; then
  touch $FILE
  chown sodexis: $FILE
  chmod 700 $FILE
fi
echo "alias lsup=\"alias | grep -v \"lsup\" | grep alias.*-up | cut -d'=' -f1 | cut -d' ' -f2 | sort | pr -t --column 4\"" > $FILE
echo "alias odoo=\"sudo /bin/bash /opt/support_files/scripts/odoo-docker/odoo-docker.sh\"" >> $FILE
echo "alias sudo='sudo '" >> $FILE

for C in `find "/opt/odoo" -maxdepth 1 -type d -not -path "/opt/odoo"`; do
  if [[ $(basename $C) =~ -odoo$ ]]; then
    if ! [[ $(basename $C) =~ ^(apps|odooexp)[a-zA-Z0-9_.-]*$ ]]; then
      if [ -f ${C}/src/dev_tools/git_update/git_update.sh ]; then
        S=test
        T=$(echo "$(basename $C)" | rev | cut -d'-' -f 2- | rev)
        S_BEFORE=${T%%"$S"*}
        S_AFTER=${T#*"$S"}
        echo "alias ${S_BEFORE}${S_AFTER}-up=\"sudo -H -u sodexis /bin/bash ${C}/src/dev_tools/git_update/git_update.sh\"" >> $FILE
      fi
    fi
  fi
done
echo "alias apps13-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/apps13-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias apps14-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/apps14-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias apps15-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/apps15-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias appstest13-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/appstest13-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias appstest14-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/appstest14-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias appstest15-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/appstest15-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias appstest16-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/appstest16-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias odooexp14-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/odooexp14-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE
echo "alias odooexp15-up=\"sudo -H -u sodexis /bin/bash /opt/odoo/odooexp15-odoo/src/dev_tools/git_update/git_update.sh\"" >> $FILE