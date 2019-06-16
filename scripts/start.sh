#!/bin/bash

# Set custom WEBROOT
if [ ! -z "$WEBROOT" ]; then
  echo "Changing root from /var/www/html to ${WEBROOT}";
  sed -i "s#root ${WEBROOT};#root ${WEBROOT};#g" /etc/nginx/sites-*/*.conf;
else
  WEBROOT=/var/www/html;
fi

source /usr/lib/git/git-setup.lib

# Prepare user volume if mounted
if [[ "$PREP_USER_VOLUME" == "1" ]]; then 
  # copy backed up user directory to mounted user volume
  rsync -a /var/lib/grav/user/ $WEBROOT/user
fi 

# remove copy of grav user directory from container
rm -rf /var/lib/grav 

# Run git pull script
/usr/bin/pull

# Enable custom nginx config files if they exist
if [ -f ${WEBROOT}/conf/nginx/nginx.conf ]; then
  cp ${WEBROOT}/conf/nginx/nginx.conf /etc/nginx/nginx.conf
fi

if [ -f ${WEBROOT}/conf/nginx/nginx-site.conf ]; then
  cp ${WEBROOT}/conf/nginx/nginx-site.conf /etc/nginx/sites-enabled/default.conf
fi

if [ -f ${WEBROOT}/conf/nginx/nginx-site-ssl.conf ]; then
  cp ${WEBROOT}/conf/nginx/nginx-site-ssl.conf /etc/nginx/sites-enabled/default-ssl.conf
fi

if [ -n "$DOMAIN" ]; then 
  sed -i "s/##DOMAIN##/${DOMAIN}/g" /etc/nginx/sites-*/default*.conf;
fi 

# Prevent config files from being filled to infinity by force of stop and restart the container
lastlinephpconf="$(grep "." /usr/local/etc/php-fpm.conf | tail -1)"
if [[ $lastlinephpconf == *"php_flag[display_errors]"* ]]; then
 sed -i '$ d' /usr/local/etc/php-fpm.conf
fi

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]] ; then
 echo php_flag[display_errors] = off >> /usr/local/etc/php-fpm.d/www.conf
else
 echo php_flag[display_errors] = on >> /usr/local/etc/php-fpm.d/www.conf
fi

# Display Version Details or not
if [[ "$HIDE_NGINX_HEADERS" == "0" ]] ; then
 sed -i "s/server_tokens off;/server_tokens on;/g" /etc/nginx/nginx.conf
else
 sed -i "s/expose_php = On/expose_php = Off/g" /usr/local/etc/php-fpm.conf
fi

# Pass real-ip to logs when behind ELB, etc
if [[ "$REAL_IP_HEADER" == "1" ]] ; then
 sed -i "s/#real_ip_header X-Forwarded-For;/real_ip_header X-Forwarded-For;/" /etc/nginx/sites-available/default.conf
 sed -i "s/#set_real_ip_from/set_real_ip_from/" /etc/nginx/sites-available/default.conf
 if [ ! -z "$REAL_IP_FROM" ]; then
  sed -i "s#172.16.0.0/12#$REAL_IP_FROM#" /etc/nginx/sites-available/default.conf
 fi
fi
# Do the same for SSL sites
if [ -f /etc/nginx/sites-available/default-ssl.conf ]; then
 if [[ "$REAL_IP_HEADER" == "1" ]] ; then
  sed -i "s/#real_ip_header X-Forwarded-For;/real_ip_header X-Forwarded-For;/" /etc/nginx/sites-available/default-ssl.conf
  sed -i "s/#set_real_ip_from/set_real_ip_from/" /etc/nginx/sites-available/default-ssl.conf
  if [ ! -z "$REAL_IP_FROM" ]; then
   sed -i "s#172.16.0.0/12#$REAL_IP_FROM#" /etc/nginx/sites-available/default-ssl.conf
  fi
 fi
fi

if [[ "$USE_GEOIP" == "1" ]]; then 
  sed -i "s/#include /etc/globals/geoip.inc;/include /etc/globals/geoip.inc;/" /etc/nginx/nginx.conf
  sed -i "s/#fastcgi_param COUNTRY_CODE/fastcgi_param COUNTRY_CODE/" /etc/nginx/fastcgi_params
  sed -i "s/#fastcgi_param COUNTRY_NAME/fastcgi_param COUNTRY_NAME/" /etc/nginx/fastcgi_params
  sed -i "s/#fastcgi_param CITY_NAME/fastcgi_param CITY_NAME/" /etc/nginx/fastcgi_params
fi 

# Set the desired timezone
if [ -n "$TIMEZONE" ]; then 
  echo date.timezone=$TIMEZONE > /usr/local/etc/php/conf.d/timezone.ini
else 
  echo date.timezone=UCT > /usr/local/etc/php/conf.d/timezone.ini
fi 

# Display errors in docker logs
if [ ! -z "$PHP_ERRORS_STDERR" ]; then
  echo "log_errors = On" >> /usr/local/etc/php/conf.d/docker-vars.ini
  echo "error_log = /dev/stderr" >> /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
 sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
 sed -i "s/post_max_size = 100M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
 sed -i "s/upload_max_filesize = 100M/upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the max_execution_time
if [ ! -z "$PHP_MAX_EXECUTION_TIME" ]; then
 sed -i "s/max_execution_time = 30/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/g" /usr/local/etc/php/conf.d/docker-vars.ini
 sed -i "s/fastcgi_read_timeout 10m;/fastcgi_read_timeout ${PHP_MAX_EXECUTION_TIME}s;/g" /etc/nginx/globals/grav.inc
else
 sed -i "s/fastcgi_read_timeout 10m;/fastcgi_read_timeout 30s;/g" /etc/nginx/globals/grav.inc
fi

# Change numerical user id to match filesystem mount
if [ ! -z "$PUID" ]; then
  if [ -z "$PGID" ]; then
    PGID=${PUID}
  fi
  usermod -u $PUID nginx
  groupmod -g $PGID nginx
fi

# reset file permissions
if [ -z "$SKIP_CHOWN" ]; then
  echo "Changing file ownership";
  chown -R nginx.nginx $WEBROOT;
  chown -R nginx.nginx /var/www/errors;
  echo "Changing directory permissions";
  find $WEBROOT -type d -exec chmod 755 {} \;
fi

# enable NAXSI firewall
if [[ "$NAXSI" == "1" ]]; then
  sed -i "s/# include \/etc\/nginx\/globals\/naxsi-site.rules/include \/etc\/nginx\/globals\/naxsi-site.rules/g" /etc/nginx/globals/grav.inc
fi

# enable PageSpeed module
if [[ "$PAGESPEED" == "1" ]]; then
  sed -i "s/# include \/etc\/nginx\/globals\/pagespeed.rules/include \/etc\/nginx\/globals\/pagespeed.rules/g" /etc/nginx/globals/grav.inc
fi

# enable fastcgi cache
if [[ "$FASTCGI_CACHE" == "1" ]]; then
  sed -i "s/# include \/etc\/nginx\/globals\/fastcgi_cache.inc/include \/etc\/nginx\/globals\/fastcgi_cache.inc/g" /etc/nginx/globals/grav.inc
fi

# enable NGINX debug headers
if [[ "$NGINX_DEBUG_HEADERS" == "1" ]]; then
  sed -i "s/# include \/etc\/nginx\/globals\/debug.inc/include \/etc\/nginx\/globals\/debug.inc/g" /etc/nginx/globals/grav.inc
fi

# enable ssl
if [[ "$SSL_ENABLED" == "1" ]]; then
  if [ -z "$DOMAIN" ]; then 
    echo "To enable SSL make sure to set DOMAIN";
    exit 1;
  fi

  if [[ "$SSL_LETS_ENCRYPT" == "1" ]]; then
    if [[ -d "/etc/letsencrypt/live/${DOMAIN}" ]]; then
      /usr/bin/letsencrypt-renew
    else
      /usr/bin/letsencrypt-setup
    fi
  fi

  sed -i "s/##DOMAIN##/${DOMAIN}/g" /etc/nginx/sites-available/default-ssl.conf;

  # redirect http to https
  if [[ "$REDIRECT_SSL" == "1" ]]; then
      rm -f /etc/nginx/sites-enabled/default.conf;
      sed -i "s/##DOMAIN##/${DOMAIN}/g" /etc/nginx/sites-available/default-redirect.conf;
      ln -s /etc/nginx/sites-available/default-redirect.conf /etc/nginx/sites-enabled/default.conf;
  fi

  # make sure NGINX is stopped
  /usr/sbin/nginx -s stop;
fi

# if there is plugins then install each
if [ ${#PLUGINS[@]} -gt 0 ]; then 
  PLUGINS="${PLUGINS},error,markdown-notices,problems"
  IFS=',';
  for plugin in $PLUGINS; do 
    su-exec nginx ${WEBROOT}/bin/gpm install -n $plugin;
  done 
  IFS=' ';
fi 

# if theme specified then install 
if [ -n "$THEME" ]; then 
  su-exec nginx ${WEBROOT}/bin/gpm install -n $THEME;
fi 

# Set custom admin URI
if [[ ! -x "$GRAV_ADMIN" ]]; then 
  echo "Setting admin URI in nginx grav config"
  sed -i "s#location /admin#location /${GRAV_ADMIN}#g" /etc/nginx/globals/grav.inc
  if [[ ! -f "${WEBROOT}/user/config/plugins/admin.yaml" ]]; then 
    if [[ ! -f "${WEBROOT}/user/plugins/admin/admin.yaml" ]]; then 
      echo "Installing admin plugin"
      su-exec nginx ${WEBROOT}/bin/gpm install -n admin 
    fi 
    echo "Copying admin.yaml to config/plugins directory"
    cp ${WEBROOT}/user/plugins/admin/admin.yaml ${WEBROOT}/user/config/plugins/admin.yaml
  fi 
  echo "Changing admin URL in "
  sed -ir "s#route:.*#route: '/${GRAV_ADMIN}'#" ${WEBROOT}/user/config/plugins/admin.yaml
fi 

# Run SMTP server to send mail
if [[ "$EMAIL_SERVER" == "1" ]]; then 

  # Install Postfix
  apk add --no-cache postfix 

  # add Postfix to supervisord config
  cat <<EOF >> /etc/supervisord.conf
[program:postfix]
process_name  = master
directory	    = /etc/postfix
command		    = /usr/sbin/postfix -c /etc/postfix start
startsecs	    = 0
autorestart   = false
EOF
fi 

# Run SMTP server to send mail
if [[ "$GIT_PUSH" == "1" ]]; then 

  # Install inotify-tools
  apk add --no-cache inotify-tools

  # add inotifywait command to supervisord config
  cat <<EOF >> /etc/supervisord.conf
[program:git-push]
command=bash -c 'while inotifywait -q -r -e create,delete,modify,move,attrib --exclude "/data/*" /var/www/html/user/; do /usr/bin/push; done'
stdout_logfile	= /dev/stdout
stderr_logfile	= /dev/stderr
autorestart     = true
EOF
fi 

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
