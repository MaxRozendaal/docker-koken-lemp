FROM phusion/baseimage:0.11
MAINTAINER Brad Daily <brad@koken.me>

ENV HOME /root

# Install required packages
# LANG=C.UTF-8 line is needed for ondrej/php5 repository
RUN \
	export LANG=C.UTF-8 && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 && \
	add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://ams2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu bionic main' && \
	add-apt-repository ppa:ondrej/php && \
	add-apt-repository -y ppa:ondrej/nginx-mainline && \
	add-apt-repository -y ppa:rwky/graphicsmagick && \
	apt-get update && \
	apt-get -y upgrade && \
	apt-get -y install nginx mariadb-server mariadb-client php7.1-fpm php7.1-mysqli php7.1-curl php7.1-intl php7.1-mbstring php7.1-mcrypt graphicsmagick pwgen wget unzip openssl

# Configuration
RUN \
	sed -i -e"s/events\s{/events {\n\tuse epoll;/" /etc/nginx/nginx.conf && \
	sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2;\n\tclient_max_body_size 100m;\n\tport_in_redirect off/" /etc/nginx/nginx.conf && \
	echo "daemon off;" >> /etc/nginx/nginx.conf && \
	sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 101M/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf && \
	phpenmod mcrypt

# nginx site conf
ADD ./conf/nginx-site.conf /etc/nginx/sites-available/default
ADD ./conf/ssl-params.conf /etc/nginx/snippets/ssl-params.conf

# PHP-FPM pools conf
ADD ./conf/images.conf /etc/php/7.1/fpm/pool.d
ADD ./conf/www.conf /etc/php/7.1/fpm/pool.d

# Add runit files for each service
ADD ./services/nginx /etc/service/nginx/run
ADD ./services/mysql /etc/service/mysql/run
ADD ./services/php-fpm /etc/service/php-fpm/run
ADD ./services/koken /etc/service/koken/run

# Installation helpers
ADD ./php/index.php /installer.php
ADD ./php/database.php /database.php
ADD ./php/user_setup.php /user_setup.php

# Cron
ADD ./shell/koken.sh /etc/cron.daily/koken

# Startup script
ADD ./shell/start.sh /etc/my_init.d/001_koken.sh

# Execute permissions where needed
RUN \
	chmod +x /etc/service/nginx/run && \
	chmod +x /etc/service/mysql/run && \
	chmod +x /etc/service/php-fpm/run && \
	chmod +x /etc/service/koken/run && \
	chmod +x /etc/cron.daily/koken && \
	chmod +x /etc/my_init.d/001_koken.sh

# Data volumes
VOLUME ["/usr/share/nginx/www", "/var/lib/mysql" "/etc/letsencrypt/live/"]

# Expose 8080 to the host
EXPOSE 8080

# Make directory for PHP sockets
RUN mkdir -p /var/run/php
RUN mkdir -p /etc/letsencrypt/live/
# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Generate strong DH group
RUN openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
