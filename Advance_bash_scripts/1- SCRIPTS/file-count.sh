#!/bin/bash
USB=/media/usb-disk/ScienceFirst-Backups/Attachments/filestore/SF_Master
WIN=/media/winshare/ScienceFirst-Backups/Attachments/filestore/SF_Master

for USB_DIR in `find "${USB}"/ -maxdepth 1 ! -path "${USB}"/ -type d`; do
    BASE_USB_DIR=`basename $USB_DIR`
    COUNT_USB_DIR=`\ls -f "$USB"/"$BASE_USB_DIR" | wc -l`
    COUNT_WIN_DIR=`\ls -f "$WIN"/"$BASE_USB_DIR" | wc -l`
    if [ "$COUNT_USB_DIR" -ne "$COUNT_WIN_DIR" ]; then
    	echo 
    	echo -------------------------------------------------------------------------------
    	echo "The Count of files in directory \"$BASE_USB_DIR\" differs betwen USB_DIR:WIN_DIR as ${COUNT_USB_DIR}:${COUNT_WIN_DIR}"
    	echo -------------------------------------------------------------------------------
    	echo "The Missing files in windows share:-"
    	for USB_DIR_FILE in `find "$USB"/"$BASE_USB_DIR"/ -type f`; do
    		BASE_USB_DIR_FILE=`basename $USB_DIR_FILE`
    		if [ ! -f "$WIN"/"$BASE_USB_DIR"/"$BASE_USB_DIR_FILE" ]; then
    			echo "$WIN"/"$BASE_USB_DIR"/"${BASE_USB_DIR_FILE}"
    		fi
    	done
    fi
done
    