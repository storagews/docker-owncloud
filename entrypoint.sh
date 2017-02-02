#!/bin/sh

# setup php-fpm
sed -i "s|POST_MAX_SIZE|${POST_MAX_SIZE}|g" /etc/php/7.0/fpm/php.ini
sed -i "s|PHP_MEMORY|${PHP_MEMORY}|g" /etc/php/7.0/fpm/php.ini
sed -i "s|PHP_MEMORY|${PHP_MEMORY}|g" /etc/php/7.0/fpm/pool.d/pool.conf
sed -i "s|PHP_PM_MAX|${PHP_PM_MAX}|g" /etc/php/7.0/fpm/pool.d/pool.conf
sed -i "s|PHP_PM_START|${PHP_PM_START}|g" /etc/php/7.0/fpm/pool.d/pool.conf
sed -i "s|PHP_PM_SPARE_MIN|${PHP_PM_SPARE_MIN}|g" /etc/php/7.0/fpm/pool.d/pool.conf
sed -i "s|PHP_PM_SPARE_MAX|${PHP_PM_SPARE_MAX}|g" /etc/php/7.0/fpm/pool.d/pool.conf
sed -i "s|PHP_DISPLAY_ERROR|${PHP_DISPLAY_ERROR}|g" /etc/php/7.0/fpm/pool.d/pool.conf
sed -i "s|PHP_SHORT_OPEN_TAG|${PHP_SHORT_OPEN_TAG}|g" /etc/php/7.0/fpm/php.ini
# setup nginx
sed -i "s|HTTP|${HTTP}|g" /localhost
sed -i "s|FQDN|${FQDN}|g" /http
sed -i "s|DAV|${DAV_FQDN}|g" /http
sed -i "s|HTTP|${HTTP}|g" /http
sed -i "s|FQDN|${FQDN}|g" /https
sed -i "s|DAV|${DAV_FQDN}|g" /https
sed -i "s|HTTPS|${HTTPS}|g" /https
# functions

setup_oc_ops () {
	mv /code/.git /.git
	find /code/* -type d -name ".git*" | xargs rm -dfR
	find /code/ -type f -exec chmod 655 {} \;
	find /code/ -type d -exec chmod 755 {} \;
	mv /.git /code/.git
}

# download code from gitlab
setup_code () {
	if [ "$REPO" = "external" ]; then
		echo "external code mode"
	else
		if ! [ -d /code/.git ]; then
			mkdir /code
			if [ "$BRANCH" = "master" ]; then
				cd /code && git init && git remote add origin https://$GIT_USER:$GIT_PASS@$REPO
		    	cd /code && git pull origin master && git branch --set-upstream-to=origin/master master
			else
				cd /code && git init && git remote add origin https://$GIT_USER:$GIT_PASS@$REPO
		    	cd /code && git pull origin master && git branch --set-upstream-to=origin/master master
		    	cd /code && git checkout ${BRANCH}
			fi
			setup_oc_ops
			# setup cron sync
			echo "*/15  *  *  *  * /sync.sh" | crontab -u root - 
		else
			/sync.sh
		fi
	fi
}

setup_nginx_le () {
	# make dhparams
	if [ ! -f /etc/nginx/ssl/dhparams.pem ]; then
    	echo "make dhparams"
    	cd /etc/nginx/ssl
    	openssl dhparam -out dhparams.pem 2048
    	chmod 600 dhparams.pem
	fi
	(
 		while :
 		do
 		if [ ! -f /etc/nginx/sites-enabled/https ]; then
 			if [ ! -f /etc/nginx/sites-enabled/http ]; then
	 			mv /http /etc/nginx/sites-enabled/http
	 		fi
 			nginx -s reload
 			sleep 3
 			/le.sh && mv /https /etc/nginx/sites-enabled/https
 			nginx -s reload
 			sleep 60d
 		else
 			if [ ! -f /etc/nginx/sites-enabled/http ]; then
	 				mv /http /etc/nginx/sites-enabled/http
	 		fi
 			mv /etc/nginx/sites-enabled/https /https 
			nginx -s reload
 			sleep 3
 			/le.sh && mv /https /etc/nginx/sites-enabled/https
 			nginx -s reload
 			sleep 60d
 		fi
 		done
	) &
}

set_oc_env () {
		sed -i "s|YA_SMTP_DOMAIN|${YA_SMTP_DOMAIN}|g" /code/config/config.php
		sed -i "s|YA_SMTP_NAME|${YA_SMTP_NAME}|g" /code/config/config.php
		sed -i "s|YA_SMTP_PASS|${YA_SMTP_PASS}|g" /code/config/config.php
		sed -i "s|SWIFT_NAME|${SWIFT_NAME}|g" /code/config/config.php
		sed -i "s|SWIFT_PASS|${SWIFT_PASS}|g" /code/config/config.php
		sed -i "s|SWIFT_CONTAINER|${SWIFT_CONTAINER}|g" /code/config/config.php
		sed -i "s|SWIFT_CREATE|${SWIFT_CREATE}|g" /code/config/config.php
		sed -i "s|DB_NAME|${DB_NAME}|g" /code/config/config.php
		sed -i "s|DB_USER|${DB_USER}|g" /code/config/config.php
		sed -i "s|DB_PASS|${DB_PASS}|g" /code/config/config.php
		sed -i "s|DB_HOST|${DB_HOST}|g" /code/config/config.php
		sed -i "s|OC_INSTANCEID|${OC_INSTANCEID}|g" /code/config/config.php
		sed -i "s|OC_PASSWORDSALT|${OC_PASSWORDSALT}|g" /code/config/config.php
		sed -i "s|OC_SECRET|${OC_SECRET}|g" /code/config/config.php
		sed -i "s|OC_VERSION|${OC_VERSION}|g" /code/config/config.php
		sed -i "s|OC_THEME|${OC_THEME}|g" /code/config/config.php
		sed -i "s|REDIS_PORT|${REDIS_PORT}|g" /code/config/config.php
		sed -i "s|REDIS_HOST|${REDIS_HOST}|g" /code/config/config.php
		sed -i "s|FQDN|${FQDN}|g" /code/config/config.php
		sed -i "s|DAV|${DAV_FQDN}|g" /code/config/config.php
}

setup_oc () {
	if [ ! -f /code/config/config.php ]; then
		cp /code/config/config.sample.php /code/config/config.php
		set_oc_env
	else
		mv /code/config/config.php /code/config/config.php.fromrepo
		cp /code/config/config.sample.php /code/config/config.php
		set_oc_env
	fi
}

if [ "$FQDN" = "example.com" ]; then
	mv /localhost /etc/nginx/sites-enabled/
else
	setup_code
	setup_oc
	/sync.sh &
	setup_nginx_le
fi
/usr/bin/supervisord
