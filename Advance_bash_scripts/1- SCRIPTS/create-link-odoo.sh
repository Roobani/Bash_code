#!/bin/bash
LINK_SOURCE_FOLDER_PATH=/opt/odoo/OCA_modules
LINK_DESTNIATION_FOLDER_PATH=/opt/odoo/OCA_modules_links
#Give repository sperated by space to get excluded during links creation. eg: EXCLUDE_REPOSITORY="OCB connector"
EXCLUDE_REPOSITORY="OpenUpgrade OCB connector-sage-50 vertical-hotel margin-analysis product-kitting"

#------------------------------------------

if [ ! -z "$EXCLUDE_REPOSITORY" ]; then
for i in $EXCLUDE_REPOSITORY; do
	args+=(-not -path ${LINK_SOURCE_FOLDER_PATH}/$i)
	for j in `find "${LINK_SOURCE_FOLDER_PATH}"/$i -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}/$i" -not -path "${LINK_SOURCE_FOLDER_PATH}/$i/.git" -not -path "${LINK_DESTNIATION_FOLDER_PATH}"`; do
		base_j=`basename $j`
		if [ -L "${LINK_DESTNIATION_FOLDER_PATH}/$base_j" ]; then
			cd $LINK_DESTNIATION_FOLDER_PATH
			echo "Checking for update link..."
			#Delete links if script run with updated EXCLUDE_REPOSITORY
			unlink "${LINK_DESTNIATION_FOLDER_PATH}"/$base_j
		fi
	done
done
fi

for D in `find "${LINK_SOURCE_FOLDER_PATH}" -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}" "${args[@]}"`; do
	base_D=`basename $D`
	#Search in /opt/odoo/OCA_modules/repository for folders (Modules), but exclude the /opt/odoo/OCA_modules/repository and /opt/odoo/OCA_modules/repository/.git 
	#find "${LINK_SOURCE_FOLDER_PATH}"/"$base_D" -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D" -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D/.git" -exec bash -c "ln -s {} \`basename {}\`" \;	
	for DD in `find "${LINK_SOURCE_FOLDER_PATH}"/"$base_D" -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D" -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D/.git"`; do
		base_DD=`basename $DD`
		if [ ! -L "${LINK_DESTNIATION_FOLDER_PATH}/$base_DD" ]; then
			echo "Creating New Link in $LINK_DESTNIATION_FOLDER_PATH"
			ln -s ${DD}/ ${LINK_DESTNIATION_FOLDER_PATH}/$base_DD 
	    fi
	done
done