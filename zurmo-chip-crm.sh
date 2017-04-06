#!/bin/bash

# Check if user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Clear the screen
reset

# Start info
echo "+-----------------------------------------------------------+"
echo "|                   CHOOSE A NEW HOSTNAME                   |"
echo "| If you want to keep chip as your hostname, just type chip |"
echo "|  Be avare that using chip as hostname can cause problems  |"
echo "|   if you have more than 1 chip connected to you network   |"
echo "+-----------------------------------------------------------+"

# Choose a new host name
read -p "Choose your new host name: " hostname_new

# Setup hostname
read -r hostname_old < /etc/hostname
sed -i "s/$hostname_old/$hostname_new/g" /etc/hostname
sed -i "s/$hostname_old/$hostname_new/g" /etc/hosts

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

# Clear screen
reset

# Finishing up
echo "+---------------------------------------------------------------------+"
echo "|                           Congratulation!                           |"
echo "|                        Your install is done.                        |"
echo "|                   Your HOSTNAME is $hostname_new                    |"
echo "|            If you don't have Bonjour/Netatalk installed,            |"
echo "|               Head over to http://your.local.ip/zurmo               |"
echo "|                                                                     |"
echo "|             If you DO have Bonjour/Netatalk installed,              |"
echo "|            Head over to http://$hostname_new.local/zurmo            |"
echo "|                        To finish your setup!                        |"
echo "|                                                                     |"
echo "| Database Hostname:    localhost                                     |"
echo "| Database Port:        3306                                          |"
echo "| Database Name:        zurmo                                         |"
echo "| Remove Existing Data: (*)                                           |"
echo "| Database Username:    root                                          |"
echo "| Database Password:    $zurmodbuserpassword                          |"
echo "| Super User Password:  Pick your poison                              |"
echo "| Memcache Hostname:    127.0.0.1                                     |"
echo "| Memcashe Port Number: 11211                                         |"
echo "| Host Info:            http://your.local.ip.address                  |"
echo "| Script URL:           /zurmo/app/index.php                          |"
echo "|                                                                     |"
echo "|                    Leave everything else blank!!                    |"
echo "|                                                                     |"
echo "|            This installer was brought to you by AllGray!            |"
echo "+---------------------------------------------------------------------+"
