FROM ubuntu:20.04
LABEL maintainer="thongminh@msn.com" description="Docker image with latest ubuntu softwares and wordpress multiple sites supported" version="20.01"

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN mkdir /var/run/sshd 
RUN mkdir /run/php

ENV container docker
ENV LC_ALL C.UTF-8
# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN apt-get -y install pwgen curl git nano sudo unzip openssh-server openssl
RUN apt-get -y install mysql-server mysql-client nginx php-fpm php-mysql
RUN mkdir /var/run/mysqld && chown mysql: /var/run/mysqld

# PHP Requirements
RUN apt-get -y install php-xml php-mbstring php-bcmath php-zip php-pdo-mysql php-curl \
    php-gd php-intl php-pear php-imagick php-imap php-memcache php-apcu php-pspell php-tidy php-xmlrpc

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# nginx config
RUN sed -i -e"s/user\s*www-data;/user webuser www-data;/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.4/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.4/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i -e "s/user\s*=\s*www-data/user = webuser/g" /etc/php/7.4/fpm/pool.d/www.conf
# replace # by ; RUN find /etc/php/7.0/mods-available/tmp -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# nginx site conf
ADD ./conf/nginx-site.conf /etc/nginx/sites-available/default

# Supervisor Config
RUN apt-get install -y supervisor && \
    #    pip3 install supervisor_stdout && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean

ADD ./conf/supervisord.conf /etc/supervisord.conf

# Add a shell user
RUN useradd -m -d /home/webuser -G root -s /bin/bash webuser \
    && usermod -a -G www-data webuser \
    && usermod -a -G sudo webuser \
    && ln -s /usr/share/nginx/www /home/webuser/www

# phpMyAdmin
RUN curl --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz | tar xzf - && \
    mv phpMyAdmin* /usr/share/phpmyadmin
ADD conf/config.inc.php /usr/share/phpmyadmin/config.inc.php
ADD conf/phpmyadmin.conf /etc/phpmyadmin/nginx.conf
RUN chown -R webuser: /usr/share/phpmyadmin

# Install the application
ADD http://wordpress.org/latest.tar.gz /usr/share/nginx/latest.tar.gz
RUN cd /usr/share/nginx/ \
    && tar xvf latest.tar.gz \
    && rm latest.tar.gz

RUN mv /usr/share/nginx/wordpress /usr/share/nginx/www \
    && curl -Os `curl -is https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+\.zip"` \
    && unzip -qo nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins \
    && chown -R webuser:www-data /usr/share/nginx/www \
    && chmod -R 775 /usr/share/nginx/www

# Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

#NETWORK PORTS
# private expose
EXPOSE 9011
EXPOSE 3306
EXPOSE 80
EXPOSE 22

# volume for mysql database and web installation
VOLUME ["/var/lib/mysql", "/usr/share/nginx/www", "/var/run/sshd"]

CMD ["/bin/bash", "/start.sh"]
