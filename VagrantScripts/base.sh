#!/usr/bin/env bash

# disable selinux for current boot
setenforce 0

# disable selinux permanently
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

yum install -q -y epel-release

# Install mariadb repo
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Enable installation after epel is installed
yum install -q -y ntp vim-enhanced wget git nodejs MariaDB-server nginx tree

# Set the correct time
ntpdate -u pool.ntp.org

# Enable & start ntp/mariadb
systemctl enable ntpd
systemctl enable mariadb
systemctl start ntpd
systemctl start mariadb

PHP_VERSION="70"
# PHP 7.0.x install:
yum install -q -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -q -y \
  php${PHP_VERSION}-php-cli \
  php${PHP_VERSION}-php-fpm \
  php${PHP_VERSION}-php-mysqli \
  php${PHP_VERSION}-php-mbstring \
  php${PHP_VERSION}-php-gd \
  php${PHP_VERSION}-php-mcrypt \
  php${PHP_VERSION}-php-zip \
  php${PHP_VERSION}-php-opcache \
  php${PHP_VERSION}-php-intl \
  php${PHP_VERSION}-php-xml

ln -s /usr/bin/php${PHP_VERSION} /usr/bin/php

# Copy config files
cp /vagrant/VagrantScripts/nginx.conf /etc/nginx/nginx.conf
cp /vagrant/VagrantScripts/www.conf /etc/opt/remi/php70/php-fpm.d/www.conf

#
chgrp vagrant /var/opt/remi/php70/lib/php/session
chgrp vagrant /var/opt/remi/php70/lib/php/wsdlcache
chgrp vagrant /var/opt/remi/php70/lib/php/opcache
chown vagrant /var/opt/remi/php70/log/php-fpm

# Increase php memory limit
sed -i 's/memory_limit = 128M/memory_limit = 770M/' /etc/opt/remi/php70/php.ini

# Create directory and database for magento
mkdir -p /services/magento
chown vagrant:vagrant -R /services/magento
mysql -u root -e"create database magento2"

# Reinstall npm packages
cd /vagrant ; rm -rf node_modules
sudo -u vagrant npm install
sudo -u vagrant npm run build

# Enable more services
systemctl enable nginx
systemctl enable php70-php-fpm

systemctl start nginx
systemctl start php70-php-fpm
