#!/bin/bash
LINK_SOURCE_FOLDER_PATH=/opt/odoo/community_modules
LINK_DESTNIATION_FOLDER_PATH=/opt/odoo/community_modules_links
#Give repository sperated by space to get excluded during links creation. eg: EXCLUDE_REPOSITORY="OCB connector", if you rerun the script adding more exclude, this script will unlink whatever in exclude.
EXCLUDE_REPOSITORY=

#------------------------------------------

if [ ! -z "$EXCLUDE_REPOSITORY" ]; then
for i in $EXCLUDE_REPOSITORY; do
	args+=(-not -path ${LINK_SOURCE_FOLDER_PATH}/$i)
	for j in `find "${LINK_SOURCE_FOLDER_PATH}/$i" -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}/$i" -not -path "${LINK_SOURCE_FOLDER_PATH}/$i/.*"`; do
		base_j=`basename $j`
		echo "Checking for links to Update..."
		if [ -L "${LINK_DESTNIATION_FOLDER_PATH}/$base_j" ]; then
			#Delete links if script run with updated EXCLUDE_REPOSITORY
			unlink "${LINK_DESTNIATION_FOLDER_PATH}/$base_j"
			echo "Removed link: ${LINK_DESTNIATION_FOLDER_PATH}/$base_j"
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
			ln -s ${DD}/ ${LINK_DESTNIATION_FOLDER_PATH}/$base_DD
			echo "Created New Link: $(ls -l $LINK_DESTNIATION_FOLDER_PATH/$base_DD)"
	    fi
	done
done