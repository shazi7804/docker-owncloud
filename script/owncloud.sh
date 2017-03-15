#!/bin/bash

# apache
tee /etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:80>
  Redirect permanent / https://$DOMAIN/
</VirtualHost>
EOF

tee /etc/apache2/sites-available/${DOMAIN}.conf <<EOF
<VirtualHost *:80>
  ServerName ${DOMAIN}
  RewriteEngine on
  RewriteCond %{SERVER_NAME} =${DOMAIN}
  RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,R=permanent]
</VirtualHost>

<VirtualHost *:443>
  # Basics
  ServerName ${DOMAIN}
  # Next line puts ownCloud at the domain root instead of a /owncloud/ subdirectory (e.g. example.com vs. example.com/owncloud/)
  DocumentRoot ${WWWROOT}

  # TLS
  SSLEngine on
  SSLCertificateFile    $SSLCERT
  SSLCertificateKeyFile $SSLKEY

  # HSTS recommended, un-comment the next line but realize it means you are committed to staying with HTTPS for the duration of the max-age value below (15768000 seconds = 6 months)
  # Header always set Strict-Transport-Security "max-age=15768000"

  # Always ensure Cookies have "Secure" set (JAH 2012/1)
  Header edit Set-Cookie (?i)^(.*)(;\s*secure)??((\s*;)?(.*)) "$1; Secure$3$4"

  # ownCloud
  <Directory ${WWWROOT}/>

    Options +FollowSymlinks
    AllowOverride All
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
    SetEnv HOME ${WWWROOT}
    SetEnv HTTP_HOME ${WWWROOT}
  </Directory>
</VirtualHost>
SSLStaplingCache        shmcb:/var/run/ocsp(128000)
EOF

# generate ssl
mkdir -p $SSLPATH
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $SSLKEY -out $SSLCERT \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$COMPANY/OU=$UNIT/CN=$DOMAIN/emailAddress=$EMAIL"

# db
service mysql start
mysql -u root -p$ROOT_DBPWD -e "create database $OWNCLOUD_DBNAME; create user $OWNCLOUD_DBUSER; set password for $OWNCLOUD_DBUSER = password('$OWNCLOUD_DBPWD'); grant all privileges on ${OWNCLOUD_DBNAME}.* TO ${OWNCLOUD_DBUSER}@${OWNCLOUD_DB} identified by '${OWNCLOUD_DBPWD}'; flush privileges;"

# php
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 10G/g; s/post_max_size =.*/post_max_size = 10G/g; s/max_execution_time =.*/max_execution_time = 3600/g'  /etc/php/7.0/apache2/php.ini

# owncloud
cd /tmp; wget --no-check-certificate https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.zip
unzip -q owncloud-${OWNCLOUD_VERSION}.zip -d /var/www/