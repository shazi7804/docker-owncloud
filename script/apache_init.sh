#!/bin/bash
SERVERNAME=$1

# add apache with owncloud *:80,443
tee /etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:80>
  ServerName $SERVERNAME

  RewriteEngine on
  RewriteCond %{SERVER_NAME} =$SERVERNAMEL
  RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,R=permanent]
</VirtualHost>

<VirtualHost *:443>
  # Basics
  ServerName $SERVERNAME
  # Next line puts ownCloud at the domain root instead of a /owncloud/ subdirectory (e.g. example.com vs. example.com/owncloud/)
  Alias /owncloud "/var/www/owncloud/"
  DocumentRoot /var/www/owncloud

  # TLS
  SSLEngine on
  SSLProtocol             all -SSLv3
  SSLCipherSuite          ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
  SSLHonorCipherOrder     on
  SSLCompression          off
  SSLSessionTickets       off
  SSLOptions +StrictRequire
  SSLCertificateFile /etc/letsencrypt/live/$SERVERNAME/cert.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$SERVERNAME/privkey.pem
  Include /etc/letsencrypt/options-ssl-apache.conf
  SSLCertificateChainFile /etc/letsencrypt/live/$SERVERNAME/chain.pem
  SSLUseStapling on

  # HSTS recommended, un-comment the next line but realize it means you are committed to staying with HTTPS for the duration of the max-age value below (15768000 seconds = 6 months)
  # Header always set Strict-Transport-Security "max-age=15768000"
  # Always ensure Cookies have "Secure" set (JAH 2012/1)
  Header edit Set-Cookie (?i)^(.*)(;\s*secure)??((\s*;)?(.*)) "$1; Secure$3$4"

  # ownCloud
  <Directory /var/www/owncloud/>
    Options +FollowSymlinks
    AllowOverride All

    <IfModule mod_dav.c>
      Dav off
    </IfModule>

    SetEnv HOME /var/www/owncloud
    SetEnv HTTP_HOME /var/www/owncloud
  </Directory>
</VirtualHost>
SSLStaplingCache        shmcb:/var/run/ocsp(128000)
EOF

# add apache mod
a2enmod autoindex \
        deflate \
        expires \
        filter \
        headers \
        include \
        mime \
        rewrite \
        setenvif \
        ssl


