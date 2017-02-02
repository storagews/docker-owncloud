FROM storagews/docker-supervisor:latest

MAINTAINER Alexander Shevchenko <kudato@me.com>

ENV EMAIL mail@example.com

ENV REPO external
ENV BRANCH master
#
ENV GIT_USER nosetuser
ENV GIT_PASS nosetpass

ENV HTTP 80
ENV HTTPS 443
#
ENV FQDN example.com
ENV DAV_FQDN webdav.example.com
#
ENV PHP_MEMORY 256M
ENV PHP_PM_MAX 10
ENV PHP_PM_START 2
ENV PHP_PM_SPARE_MIN 2
ENV PHP_PM_SPARE_MAX 4
#
ENV POST_MAX_SIZE 8192
ENV PHP_DISPLAY_ERROR Off
ENV PHP_SHORT_OPEN_TAG Off
#
ENV YA_SMTP_DOMAIN example.com
ENV YA_SMTP_NAME nosetuser
ENV YA_SMTP_PASS nosetpass
#
ENV SWIFT_NAME nosetuser
ENV SWIFT_PASS nosetpass
ENV SWIFT_CONTAINER default
ENV SWIFT_CREATE false

ENV DB_NAME owncloud
ENV DB_USER owncloud
ENV DB_PASS nosetpass

ENV REDIS_PORT 6379
ENV REDIS_HOST 127.0.0.1

ENV OC_INSTANCEID noset
ENV OC_PASSWORDSALT none
ENV OC_SECRET none

ENV OC_VERSION noset
ENV OC_THEME mycloud

# update lists
RUN apt-get update && apt-get upgrade -y
# letsencrypt
RUN apt-get install -y letsencrypt
ADD le.sh /le.sh
ADD localhost /localhost
# nginx
RUN apt-get install -y nginx git curl nano && \
	echo "[program:nginx]" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "command = /usr/sbin/nginx" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "autostart = true" >> /etc/supervisor/conf.d/supervisord.conf && \
	rm -rf /etc/nginx/sites-enabled/* && mkdir -p /usr/share/nginx/html
ADD nginx.conf /etc/nginx/
ADD http /http
ADD https /https
# php
RUN mkdir -p /run/php/
RUN apt-get install -y php7.0-fpm php7.0-common php7.0-cli php-apcu && \
	apt-get install -y php-redis php-mbstring php7.0-mysql php7.0-curl php7.0-gd php7.0-intl && \
	apt-get install -y php-pear imagemagick php7.0-imagick php-imagick php7.0-imap php7.0-mcrypt && \
	apt-get install -y php7.0-pspell php7.0-recode php-patchwork-utf8 php7.0-json libxml-rss-perl && \
	apt-get install -y zlib1g php7.0-ldap php7.0-sqlite php7.0-tidy php7.0-xmlrpc php7.0-xsl && \
	apt-get install -y php7.0-zip php-iconv php7.0-iconv && \
	echo "[program:php-fpm7.0]" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "command = /usr/sbin/php-fpm7.0" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "autostart = true" >> /etc/supervisor/conf.d/supervisord.conf && rm -rf /etc/php
ADD php /etc/php
# cron
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y cron && \
	echo "[program:cron]" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "command = /usr/sbin/cron -f" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "user = root" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "autorestart = true" >> /etc/supervisor/conf.d/supervisord.conf
RUN echo "*/15  *  *  *  * php -f /code/cron.php" | crontab -u www-data -
# mysql support
# RUN apt-get install -y  mysql-client libmysqlclient-dev
# samba shares support
RUN apt-get install -y smbclient
# LibreOffice for preview
RUN apt-get -y install --no-install-recommends libreoffice
#
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chmod +x /le.sh && \
	mkdir /etc/nginx/ssl
ADD sync.sh /sync.sh
RUN chmod +x /sync.sh && apt-get clean 
###########################################################################
CMD ["/entrypoint.sh"]
