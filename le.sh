#!/bin/sh
letsencrypt certonly -t -n --agree-tos --renew-by-default --email "${EMAIL}" --webroot -w /usr/share/nginx/html -d $FQDN -d $DAV_FQDN
cp -fv /etc/letsencrypt/live/$FQDN/privkey.pem /etc/nginx/ssl/ssl.key
cp -fv /etc/letsencrypt/live/$FQDN/fullchain.pem /etc/nginx/ssl/ssl.crt
