#!/bin/bash
if [ ! -f /dbuser-pw.txt ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --user=mysql --log-error=/var/log/mysql/error.log --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=3306 &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    DBNAME="maindb"
    DBPASSWORD=`pwgen -c -n -1 12`
    DBUSER="dbuser"
    #This is so the passwords show up in logs.

    echo DB PASSWORD: $DBPASSWORD
    echo $DBPASSWORD > /dbuser-pw.txt

    mysql -uroot -e "create database $DBNAME"
    mysql -uroot -e "CREATE USER $DBUSER@localhost IDENTIFIED WITH mysql_native_password BY '$DBPASSWORD';"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER@localhost;"
    killall mysqld
fi

if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
    DBNAME="maindb"
    DBUSER="dbuser"
    DBPASSWORD=`cat /dbuser-pw.txt`
    sed -e "s/database_name_here/$DBNAME/
    s/username_here/$DBUSER/
    s/password_here/$DBPASSWORD/
    /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

    # Download nginx helper plugin
    curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+\.zip"`
    unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins

    # Activate nginx plugin and set up pretty permalink structure once logged in
    cat << ENDL >> /usr/share/nginx/www/wp-config.php
    \$plugins = get_option( 'active_plugins' );
    if ( count( \$plugins ) === 0 ) {
    require_once(ABSPATH .'/wp-admin/includes/plugin.php');
    \$wp_rewrite->set_permalink_structure( '/%postname%/' );
    \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php' );
    foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/share/nginx/www/wp-content/plugins/' . \$plugin );
    }
    }
    }
ENDL

fi

# start all the services
/usr/bin/supervisord -n -c /etc/supervisord.conf