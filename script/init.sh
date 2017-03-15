#!/bin/bash

# apache
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

# db
service mysql start
service mysql status
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${ROOT_DBPWD}') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
