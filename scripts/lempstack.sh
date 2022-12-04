#!/bin/bash
# Script author: Bytes Crafter
# Script site: https://www.bytescrafter.net
# Script date: 19-04-2020
# Script ver: 1.0
# Script use to install LEMP stack on Debian 10
#--------------------------------------------------
# Software version:
# 1. OS: 10.3 (Buster) 64 bit
# 2. Nginx: 1.14.2
# 3. MariaDB: 10.3
# 4. PHP 7: 7.3.3-1+0~20190307202245.32+stretch~1.gbp32ebb2
#--------------------------------------------------
# List function:
# 1. bc_checkroot: check to make sure script can be run by user root
# 2. bc_update: update all the packages
# 3. bc_install: funtion to install LEMP stack
# 4. bc_init: function use to call the main part of installation
# 5. bc_main: the main function, add your functions to this place

# Function check user root
bc_checkroot() {
    if (($EUID == 0)); then
        # If user is root, continue to function bc_init
        bc_init
    else
        # If user not is root, print message and exit script
        echo "Bytes Crafter: Please run this script by user root ."
        exit
    fi
}

# Function update os
bc_update() {
    echo "Bytes Crafter: Initiating Update and Upgrade..."
    echo ""
    sleep 1
        apt update
        apt upgrade -y
    echo ""
    sleep 1
}

# Function install LEMP stack
bc_install() {

    ########## INSTALL NGINX ##########
    echo ""
    echo "Bytes Crafter: Installing NGINX..."
    echo ""
    sleep 1
        apt install nginx -y
        systemctl enable nginx && systemctl restart nginx
    echo ""
    sleep 1

    ########## INSTALL MARIADB ##########
    echo "Bytes Crafter: Installing MARIADB..."
    echo ""
    sleep 1
        apt install mariadb-server -y
        systemctl enable mysql && systemctl restart mysql
    echo ""
    sleep 1

    echo "Bytes Crafter: CREATING DB and USER ..."
    echo ""
        mysql -uroot -proot -e "CREATE DATABASE test /*\!40100 DEFAULT CHARACTER SET utf8 */;"
        mysql -uroot -proot -e "CREATE USER test@localhost IDENTIFIED BY 'test';"
        mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON test.* TO 'test'@'localhost';"
        mysql -uroot -proot -e "FLUSH PRIVILEGES;"
    echo ""
    sleep 1

    ########## INSTALL PHP7 ##########
    # This is unofficial repository, it's up to you if you want to use it.
    echo "Bytes Crafter: Installing PHP 7.3..."
    echo ""
    sleep 1
        apt install php7.3 php7.3-cli php7.3-common php7.3-fpm php7.3-gd php7.3-mysql -y
    echo ""
    sleep 1

    ########## MODIFY GLOBAL CONFIGS ##########
    echo "Bytes Crafter: Modifying Global Configurations..."
    echo ""
    sleep 1
        sed -i 's:# Basic Settings:client_max_body_size 24m;:g' /etc/nginx/nginx.conf
        sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 12M/g' /etc/php/7.3/fpm/php.ini
        sed -i 's/post_max_size = 2M/post_max_size = 12M/g' /etc/php/7.3/fpm/php.ini
    echo ""
    sleep 1

    ########## PREPARE DIRECTORIES ##########
    echo "Bytes Crafter: Preparing Test directory..."
    echo ""
    sleep 1
        mkdir /var/www/test
        echo "<?php phpinfo(); ?>" >/var/www/test/info.php
        chown -R www-data:www-data /var/www/test
    echo ""
    sleep 1

    ########## MODIFY VHOST CONFIG ##########
    echo "Bytes Crafter: Modifying Default VHost for Nginx..."
    echo ""
    sleep 1
cat >/etc/nginx/sites-enabled/default <<"EOF"
server {
    listen 80;

    set $root_path '/var/www/test';
    server_name test;

    index index.html index.htm index.php;
    root $root_path;
    try_files $uri $uri/ @rewrite;
    sendfile off;
     
    include /etc/nginx/mime.types;

    # Block access to sensitive files and return 404 to make it indistinguishable from a missing file
    location ~* .(ini|sh|inc|bak|twig|sql)$ {
        return 404;
    }

    # Block access to hidden files except .well-known
    location ~ /\.(?!well-known\/) {
        return 404;
    }

    # Disable PHP execution in /bb-uploads
    location ~* /bb-uploads/.*\.php$ {
        return 404;
    }
        
    # Deny access to /bb-data
    location ~* /bb-data/ {
        return 404;
    }

    location @rewrite {
        rewrite ^/page/(.*)$ /index.php?_url=/custompages/$1;
        rewrite ^/(.*)$ /index.php?_url=/$1;
    }

    location ~ \.php {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;

        # fastcgi_pass need to be changed according your server setup:
        # phpx.x is your server setup
        # examples: /var/run/phpx.x-fpm.sock, /var/run/php/phpx.x-fpm.sock or /run/php/phpx.x-fpm.sock are all valid options 
        # Or even localhost:port (Default 9000 will work fine) 
        # Please check your server setup

        fastcgi_pass unix:/run/php/phpx.x-fpm.sock

        fastcgi_param PATH_INFO       $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_intercept_errors on;

        include fastcgi_params;
    }

    location ~* ^/(css|img|js|flv|swf|download)/(.+)$ {
        root $root_path;
        expires off;
    }
}

EOF
    echo ""
    sleep 1

    ########## RESTARTING NGINX AND PHP ##########
    echo "Bytes Crafter: Restarting Nginx & PHP..."
    echo ""
    sleep 1
        systemctl restart nginx
        systemctl restart php7.3-fpm
    echo ""
    sleep 1

    ########## INSTALLING TEST ##########
    echo "Bytes Crafter: Installing Test..."
    echo ""
        wget -c https://fossbilling.org/downloads/stable
        unzip stable
        rsync -av test/* /var/www/test/
        chown -R www-data:www-data /var/www/test/
        chmod -R 755 /var/www/test/
    echo ""
    sleep 1

    ########## ENDING MESSAGE ##########
    sleep 1
    echo ""
        local start="Bytes Crafter: You can access http://"
        local mid=`ip a | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
        local end="/ to setup your test."
        echo "Bytes Crafter: $start$mid$end"
        echo "Bytes Crafter: MySQL db: test user: test pwd: test "
        echo "Bytes Crafter: Thank you for using our script, Bytes Crafter! ..."
    echo ""
    sleep 1

}

# initialized the whole installation.
bc_init() {
    bc_update
    bc_install
}

# primary function check.
bc_main() {
    bc_checkroot
}
bc_main
exit
