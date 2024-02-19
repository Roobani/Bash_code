#!/bin/sh
# Modified script from Carlos E. Fonseca Zorrilla

yum -y install wget unzip
#install vmware tools

if [ $(id -u) != "0" ]; then
   echo " "
   echo -e "\e[5mYou must be the superuser to run this script" >&2
   su -c "$0 $@"
#   echo " "
   exit 
fi

sudo apt-get update && sudo apt-get install build-essential linux-headers-$(uname -r)
sudo ln -s /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/version.h

sudo mount /dev/cdrom /mnt
cp /mnt/VM* /tmp
sudo umount /dev/cdrom
cd /tmp
tar xzvf VM*
cd vmware-tools*
sudo ./vmwaretool-install.pl -d

#openerp Installation.

sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get install python-software-properties -y
sudo add-apt-repository ppa:pitti/postgresql -y
sudo apt-get update
sudo apt-get install postgresql-9.2 -y


sudo su - postgres -c "createuser --createdb --username postgres -s --pwprompt openerp"

sudo apt-get install bzr
sudo apt-get install python-dateutil python-docutils python-feedparser python-gdata \
python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid \
python-psycopg2 python-psutil python-pybabel python-pychart python-pydot python-pyparsing \
python-reportlab python-simplejson python-tz python-unittest2 python-vatnumber python-vobject \
python-webdav python-werkzeug python-xlwt python-yaml python-zsi -y

sudo adduser --system --home=/opt/openerp --group openerp


yum -y install postgresql92-libs postgresql92-server postgresql92
service postgresql-9.2 initdb
chkconfig postgresql-9.2 on
service postgresql-9.2 start


function openerp ()
{
DIR="/var/log/openerp"
for NAME in $DIR
do
if [ ! -d $NAME ]; then
   mkdir $NAME
   chown openerp.openerp $NAME
fi
done

bzr branch lp:openerp-web/7.0 web
bzr branch lp:openobject-server/7.0 server
bzr branch lp:openobject-addons/7.0 addons
}

export -f openerp
sudo su - openerp -s /bin/bash -c 'openerp'

sudo cp /opt/openerp/server/install/openerp-server.conf /etc/openerp-server.conf
sudo nano /etc/openerp-server.conf



sudo apt-get install python-pip -y
sudo pip install gdata --upgrade

wget http://nightly.openerp.com/7.0/nightly/src/openerp-7.0-latest.tar.gz
tar -zxvf openerp-7.0-latest.tar.gz  --transform 's!^[^/]\+\($\|/\)!openerp\1!'
cd openerp
python setup.py install
rm -rf /usr/local/bin/openerp-server
cp openerp-server /usr/local/bin
cp install/openerp-server.init /etc/init.d/openerp
cp install/openerp-server.conf /etc
chown openerp:openerp /etc/openerp-server.conf
chmod u+x /etc/init.d/openerp
chkconfig openerp on
service  openerp start