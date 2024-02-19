#!/bin/bash
LINK_SOURCE_FOLDER_PATH=/opt/odoo/community_modules
LINK_DESTNIATION_FOLDER_PATH=/opt/odoo/community_modules_links
#Give repository sperated by space to get excluded during links creation. eg: EXCLUDE_REPOSITORY="OCB connector"
EXCLUDE_REPOSITORY=

#------------------------------------------

if [ ! -z "$EXCLUDE_REPOSITORY" ]; then
for i in $EXCLUDE_REPOSITORY; do
	args+="-not -path ${LINK_SOURCE_FOLDER_PATH}/$i "
	cd $LINK_DESTNIATION_FOLDER_PATH
	echo "Checking for update link..."
	#Delete links if script run with updated EXCLUDE_REPOSITORY
	for j in `find "${LINK_SOURCE_FOLDER_PATH}"/$i -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}" -not -path "${LINK_SOURCE_FOLDER_PATH}/.git" -not -path "${LINK_DESTNIATION_FOLDER_PATH}"`; do
	    base_j=`basename $j`
		unlink "${LINK_DESTNIATION_FOLDER_PATH}"/$base_j
	done
done
fi

for D in `find "${LINK_SOURCE_FOLDER_PATH}" -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}" "${args[@]}"`; do
	cd $LINK_DESTNIATION_FOLDER_PATH
	echo Into the directory $LINK_DESTNIATION_FOLDER_PATH
	base_D=`basename $D`
	#Search in /opt/odoo/OCA_modules/repository for folders (Modules), but exclude the /opt/odoo/OCA_modules/repository and /opt/odoo/OCA_modules/repository/.git 
	find "${LINK_SOURCE_FOLDER_PATH}"/"$base_D" -maxdepth 1 -type d -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D" -not -path "${LINK_SOURCE_FOLDER_PATH}/$base_D/.git" -exec bash -c "ln -s {} \`basename {}\`" \;	
done