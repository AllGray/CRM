#!/bin/bash

# Check if user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Grab a password for MySQL Root
read -s -p "Enter the password that will be used for MySQL Root: " mysqlrootpassword
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysqlrootpassword"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysqlrootpassword"

# Grab a password for Zurmo Database User Account
read -s -p "Enter the password that will be used for the zurmo database: " zurmodbuserpassword

# Install Features
sudo apt-get install apache2 mysql-server php5 php5-mysql php5-curl php5-mcrypt php5-imap php5-ldap php5-memcache php5-apcu memcached

# If Apt-Get fails to run completely the rest of this isn't going to work...
if [ $? != 0 ]
then
    echo "Make sure to run: sudo apt-get update && sudo apt-get upgrade"
    exit
fi

# Download Zurmo Files
curl http://build.zurmo.com/downloads/zurmo-stable-3.2.1.57987acc3018.tar.gz | tar -C /var/www/html/ -xz


# Make Changes to the PHP 
sed -ie 's/^memory_limit =.*$/memory_limit = 256M/g' /etc/php5/apache2/php.ini
sed -ie 's/^upload_max_filesize =.*$/upload_max_filesize = 20M/g' /etc/php5/apache2/php.ini
sed -ie 's/^post_max_size =.*$/post_max_size = 20M/g' /etc/php5/apache2/php.ini
sed -ie 's/^max_execution_time =.*$/max_execution_time = 300/g' /etc/php5/apache2/php.ini

# Give apache access to Zurmo
sudo chown -R www-data /var/www/html/zurmo

# Restart Apache
systemctl restart apache2

# Create zurmo DB and grant zurmo User permissions to it

# SQL Code
SQLCODE="
create database zurmo;
create user 'zurmo'@'localhost' identified by \"$zurmodbuserpassword\";
GRANT SELECT,INSERT,UPDATE,DELETE ON zurmo.* TO 'zurmo'@'localhost';
flush privileges;"

# Execute SQL Code
echo $SQLCODE | mysql -u root -p$mysqlrootpassword

# Finishing up
echo "+---------------------------------------------------------------------+"
echo "|                         Congratulation!                             |"
echo "|                      Your install is done.                          |"
echo "| You can now access http://your.local.ip.address from your browser   |"
echo "|                       To finish your setup                          |"
echo "|                                                                     |"
echo "|                                                                     |"
echo "|                                                                     |"
echo "|                                                                     |"
echo "|                                                                     |"
echo "|            This installer was brought to you buy AllGray            |"
echo "+---------------------------------------------------------------------+"
