#!/bin/bash
LINK_SOURCE_FOLDER_PATH=/opt/odoo/OCA_modules
LINK_DESTNIATION_FOLDER_PATH=/opt/odoo/OCA_modules_links
#Give repository sperated by space to get excluded during links creation.
EXCLUDE_REPOSITORY="OpenUpgrade OCB connector-sage-50 vertical-hotel margin-analysis product-kitting"

#------------------------------------------

for i in $EXCLUDE_REPOSITORY; do
	args+="-not -path ${LINK_SOURCE_FOLDER_PATH}/$i "
	cd $LINK_DESTNIATION_FOLDER_PATH
	#Delete links if script run with updated EXCLUDE_REPOSITORY
	find "${LINK_SOURCE_FOLDER_PATH}"/$i -maxdepth 1 -type d -not -path "${LINK_DESTNIATION_FOLDER_PATH}" -exec bash -c "rm -fi {} \`basename {}\`" \; 
done

for D in `find "${LINK_SOURCE_FOLDER_PATH}" -maxdepth 1 -type d -not -path "${LINK_DESTNIATION_FOLDER_PATH}" "${args[@]}"`; do
	cd $LINK_DESTNIATION_FOLDER_PATH
	echo Into the directory $LINK_DESTNIATION_FOLDER_PATH
	base_D=`basename $D`
	#Search in /opt/odoo/OCA_modules/repository for folders (Modules), but exclude the /opt/odoo/OCA_modules/repository and /opt/odoo/OCA_modules/repository/.git 
	find "${LINK_SOURCE_FOLDER_PATH}"/"$base_D" -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D" -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D/.git" -exec bash -c "ln -s {} \`basename {}\`" \;	
done