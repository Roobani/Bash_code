#!/bin/bash
#======= ScienceFirst =======
SF_USER=openerp
SF_ADDRESS=openerp.sciencefirst.com
SF_OPENERP_LOG=/var/log/openerp/
SF_SODEXIS_OPENERP_LOG=/var/www/vhosts/sodexis.com/log.sodexis.com/oldlogs/Sciencefirst_Production_Server/OpenERP_Logs/
SF_PSQL_LOG=/var/log/psql/
SF_SODEXIS_PSQL_LOG=/var/www/vhosts/sodexis.com/log.sodexis.com/oldlogs/Sciencefirst_Production_Server/PostgreSQL_Logs/
#----------------------------
rsync -aur -e "ssh -p 2298" --delete "$SF_USER"@"$SF_ADDRESS":"$SF_OPENERP_LOG" "$SF_SODEXIS_OPENERP_LOG"
sleep 10
rsync -aur -e "ssh -p 2298" --delete "$SF_USER"@"$SF_ADDRESS":"$SF_PSQL_LOG" "$SF_SODEXIS_PSQL_LOG"
#=============================
