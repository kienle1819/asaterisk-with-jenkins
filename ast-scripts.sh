#!/bin/bash
###############################################################################
#Script Name    : script asterisk 16                       
#Description    : Building asterisk system on Centos7              
#Author         : Mr.Kien Le    
################################################################################

# Disabling SeLinux for installation(Remains disabled untill reboot ar manual enable). 
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

#update timzone
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

# Updating packages
yum -y update

# Installing needed tools and packages
yum -y groupinstall core base "Development Tools"

#Installing additional required dependencies
yum -y install automake gcc gcc-c++ ncurses-devel openssl-devel libxml2-devel unixODBC-devel libcurl-devel libogg-devel libvorbis-devel speex-devel spandsp-devel freetds-devel net-snmp-devel iksemel-devel corosynclib-devel newt-devel popt-devel libtool-ltdl-devel lua-devel sqlite-devel radiusclient-ng-devel portaudio-devel neon-devel libical-devel openldap-devel gmime-devel mysql-devel bluez-libs-devel jack-audio-connection-kit-devel gsm-devel libedit-devel libuuid-devel jansson-devel libsrtp-devel git subversion libxslt-devel kernel-devel audiofile-devel gtk2-devel libtiff-devel libtermcap-devel ilbc-devel bison php php-mysql php-process php-pear php-mbstring php-xml php-gd tftp-server httpd sox tzdata mysql-connector-odbc mariadb mariadb-server fail2ban jwhois xmlstarlet ghostscript libtiff-tools python-devel patch

# Compiling and Installing jansson
cd /usr/src
wget -O jansson.zip https://codeload.github.com/akheron/jansson/zip/master
unzip jansson.zip
rm -f jansson.zip
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install

#Compile and install DAHDI if needed

cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-2.10.2+2.10.2.tar.gz
tar zxvf dahdi-linux-complete-2.10*
cd /usr/src/dahdi-linux-complete-2.10*/
make all && make install && make config
systemctl restart dahdi 
echo -e "\e[32mDAHDI Install OK!\e[m"

#Compile and install Libpri if needed
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
tar xvfz libpri-current.tar.gz
cd /usr/src/libpri-*
make
make install
echo -e "\e[32mLibpri Install OK!\e[m"

# Create Asterisk usser for system
adduser asterisk -m -c "Asterisk User"

# Downloading Asterisk source files.
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz

# Compiling and installing Asterisk
cd /usr/src
tar xvfz asterisk-16-current.tar.gz
rm -f asterisk-16-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled
contrib/scripts/get_mp3_source.sh
menuselect/menuselect --enable app_macro --enable format_mp3 menuselect.makeopts

# Installation itself
make
make install
make samples
make config
ldconfig
systemctl start asterisk
systemctl enable asterisk

# Setting Asterisk ownership permissions.
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/
echo -e "\e[32m asterisk Install OK!\e[m"

# Alow porrt access asterisk and drop scan asterisk amonymous
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --permanent --zone=public --add-port=5060-5061/tcp
firewall-cmd --permanent --zone=public --add-port=5060-5061/udp
firewall-cmd --permanent --zone=public --add-port=10000-20000/udp
firewall-cmd --reload
reboot
