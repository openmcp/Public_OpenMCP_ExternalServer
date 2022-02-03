#!/bin/bash
# MY_ADDRESS=`hostname -I`
MY_ADDRESS=`ip route get 8.8.8.8 | head -1 | cut -d' ' -f8`
ORG_DIR=`pwd`
OS="Ubuntu16.04"
#OS="Ubuntu18.04"

# PASSWORD
PW="1234"

# apt Update & Upgrade
apt update
apt upgrade -y


# package Install
apt-get install -y curl
apt-get install -y git
apt-get install -y virtualenv

# Install MariaDB Server
sudo apt-get install -y software-properties-common
if [ $OS == "Ubuntu18.04" ]
then
	## For Ubuntu 18.04
	sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
	sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.nxthost.com/mariadb/repo/10.3/ubuntu bionic main'
elif [ $OS == "Ubuntu16.04" ]
then
	## For Ubuntu 16.04
	sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
	sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.nxthost.com/mariadb/repo/10.3/ubunt xenial main'
fi

sudo apt update

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password password '$PW
debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password_again password '$PW

sudo apt-get install mariadb-server mariadb-client -y

cp my.cnf /etc/mysql/my.cnf

systemctl restart mysql

# DB "powedns" Create & Insert
mysql -uroot -p$PW -e "CREATE DATABASE powerdns"
mysql -uroot -p$PW -e "GRANT ALL ON powerdns.* TO 'powerdns'@'localhost' IDENTIFIED BY '$PW'"
mysql -uroot -p$PW -e "FLUSH PRIVILEGES"
mysql -uroot -p$PW powerdns < powerdns.sql


# resoved Service Stop
systemctl disable systemd-resolved
systemctl stop systemd-resolved

# ReCreate Resolve.conf
unlink /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Pdns Install
if [ $OS == "Ubuntu18.04" ]
then
	## For Ubuntu 18.04
	echo "deb [arch=amd64] http://repo.powerdns.com/ubuntu bionic-auth-41 main" > /etc/apt/sources.list.d/pdns.list
	cp preferences /etc/apt/preferences.d/pdns
	curl https://repo.powerdns.com/FD380FBB-pub.asc | apt-key add -
	apt update
fi
apt install pdns-server pdns-backend-mysql pdns-backend-geoip -y

# Mysql Conf Setting
cp pdns.local.gmysql.conf /etc/powerdns/pdns.d/pdns.local.gmysql.conf
sed -i "s/changeme/${PW}/" /etc/powerdns/pdns.d/pdns.local.gmysql.conf

# Pdns Conf Setting
if [ $OS == "Ubuntu16.04" ]
then
	## For Ubuntu 16.04
	cp pdns.conf.16 /etc/powerdns/pdns.conf
elif [ $OS == "Ubuntu18.04" ]
then
	## For Ubuntu 18.04
	cp pdns.conf.18 /etc/powerdns/pdns.conf
fi

sed -i "s/<IPADDRESS>/${MY_ADDRESS}/" /etc/powerdns/pdns.conf


# Pdns Geo Setting
cp zone /etc/powerdns/zone

if [ $OS == "Ubuntu16.04" ]
then
	sudo sed -i 's/^dns=dnsmasq/#&/' /etc/NetworkManager/NetworkManager.conf
	sudo service network-manager restart
	sudo service networking restart
	sudo killall dnsmasq
fi

# Pdns Restart
systemctl restart pdns

# Verify PowerDNS Server Response
dig @127.0.0.1


# Package Install
apt-get install -y python3-dev
apt-get install -y libmysqlclient-dev python-mysqldb libsasl2-dev libffi-dev
apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev xmlsec1

# Yarn Install
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
apt update
apt-get install -y yarn

# PowerDNS Admin Download
#git clone https://github.com/ngoduykhanh/PowerDNS-Admin.git /opt/web/powerdns-admin
mkdir -p /opt/web
cp -r powerdns-admin /opt/web/

# Install Package for PowerDNS
cd /opt/web/powerdns-admin
sed -i 's/changeme/'$PW'/g' config.py

virtualenv -p python3 flask
source flask/bin/activate
apt-get install -y libxml2-dev libxmlsec1-dev libxmlsec1-openssl
pip install -r requirements.txt

#if [ $OS == "Ubuntu16.04" ]
#then
#	pip install werkzeug==0.16.0
#	pip install authlib
#	pip install flask_seasurf
#	pip install pytimeparse
#	pip install PyOpenSSL
#	pip install pytz
#	pip install lima
#	pip install pyyaml
#	pip install jsmin
#	pip install cssmin
# pip install flask-migrate==2.2.1
# pip install flask-login==0.4.1
# pip install flask-assets==0.12
# pip install flask-seasurf==0.2.2
# pip install flask-sqlalchemy==2.3.2
#fi

# PowerDNS-Admin Setting
# Done


# DB Schema Create
mysql -uroot -p$PW -D powerdns -e "DROP TABLE account"
mysql -uroot -p$PW -D powerdns -e "DROP TABLE domain_template"

export FLASK_APP=app/__init__.py
flask db upgrade

# DB Migrate
flask db migrate -m "Init DB"

# asset File Create
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt-get install -y nodejs
yarn install --pure-lockfile
flask assets build

cd $ORG_DIR
# PowerDNS-Admin Service
cp powerdns-admin.service /etc/systemd/system/powerdns-admin.service

systemctl daemon-reload
systemctl start powerdns-admin
systemctl enable powerdns-admin

# Nginx Proxy Install
apt-get install nginx -y
cp powerdns-admin.conf /etc/nginx/conf.d/powerdns-admin.conf
sed -i "s/<IPADDRESS>/${MY_ADDRESS}/" /etc/nginx/conf.d/powerdns-admin.conf

nginx -t
systemctl reload nginx


# powerdns-recursor (외부도메인도 사용할수 있게 해줌)
apt-get install -y pdns-recursor
cp recursor.conf /etc/powerdns/recursor.conf
echo "recursor=127.0.0.1:5678" >> /etc/powerdns/pdns.d/pdns.local.gmysql.conf

systemctl daemon-reload
systemctl restart pdns
systemctl restart pdns-recursor.service
