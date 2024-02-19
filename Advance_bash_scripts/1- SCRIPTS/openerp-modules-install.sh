#!/bin/bash

#Libreoffice to remove. 0 means package not installed. 1 means installed.
if [ $(dpkg-query -W -f='${Status}' libreoffice* 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
	echo "Preparing to remove Libre office..."
  	sudo apt-get -y remove --purge libreoffice* libexttextcat-data* && sudo apt-get -y autoremove
  	wait $!
  	echo
  	echo "LibreOffice Uninstalled."
else
	echo
	echo "LibreOffice Not Found."
fi

#OpenOffice to install
if [ $(dpkg-query -W -f='${Status}' openoffice 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
	echo "Preparing to install OpenOffice..."
	echo 
	echo "OpenOffice is already Installed"
else
	echo
	

DIRECTORY=/opt/support_files
if [ $(id -u) != "0" ]; then
   echo " "
   echo -e "\e[5mYou must be the ROOT to run this script, become root using 'sudo su'" >&2
   su -c "$0 $@"
#   echo " "
   exit 
fi

if [ ! -d "$DIRECTORY" ]; then
  sudo mkdir $DIRECTORY
fi

cd $DIRECTORY

yum -y install wget unzip python-pip python-setuptools python-dev libgmp3-dev python-beautifulsoup

sudo pip install num2words urllib3 xlrd xlutils xlsxwriter

echo /usr/local/lib >> /etc/ld.so.conf
ldconfig

wget http://ftp.dlitz.net/pub/dlitz/crypto/pycrypto/pycrypto-2.6.tar.gz
tar -xvzf pycrypto-2.6.tar.gz
cd pycrypto-2.6
sudo python setup.py build
sudo python setup.py build install
cd ..

wget https://pypi.python.org/packages/source/r/requests/requests-0.14.2.tar.gz
tar -xzvf requests-0.14.2.tar.gz
cd requests-0.14.2
sudo python setup.py build
sudo python setup.py install
cd ..

urllib3