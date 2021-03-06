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
  echo "Copying backed up user directory to mounted user volume"
  rsync -a /var/lib/grav/user/ $WEBROOT/user
fi 

echo "Removing copy of grav user directory from container"
rm -rf /var/lib/grav 

echo "Running git pull script"
/usr/bin/pull

# Enable custom nginx config files if they exist
if [ -f ${WEBROOT}/user/config/nginx/nginx.conf ]; then
  cp ${WEBROOT}/user/config/nginx/nginx.conf /etc/nginx/nginx.conf
fi

if [ -f ${WEBROOT}/user/config/nginx/nginx-site.conf ]; then
  cp ${WEBROOT}/user/config/nginx/nginx-site.conf /etc/nginx/sites-enabled/default.conf
fi

if [ -f ${WEBROOT}/user/config/nginx/nginx-site-ssl.conf ]; then
  cp ${WEBROOT}/user/config/nginx/nginx-site-ssl.conf /etc/nginx/sites-enabled/default-ssl.conf
fi

if [ -n "$DOMAIN" ]; then 
  echo "Adding domain ${DOMAIN} to NGINX configs"
  sed -i "s/##DOMAIN##/${DOMAIN}/g" /etc/nginx/sites-*/default*.conf;
fi 

echo "Prevent PHP config files from being filled to infinity by force of stop and restart the container"
sed -i '/display_errors/d' /usr/local/etc/php-fpm.conf
sed -i '/display_errors/d' /usr/local/etc/php-fpm.d/www.conf

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]] ; then
  echo "Turning off PHP display_errors"
  echo php_flag[display_errors] = off >> /usr/local/etc/php-fpm.d/www.conf
else
  echo "Turning on PHP display_errors"
  echo php_flag[display_errors] = on >> /usr/local/etc/php-fpm.d/www.conf
fi

# Display Version Details or not
if [[ "$HIDE_NGINX_HEADERS" == "0" ]] ; then
  echo "Turning NGINX server_tokens on"
  sed -i "s/server_tokens off;/server_tokens on;/g" /etc/nginx/nginx.conf
else
  echo "Turning NGINX expose_php off"
  sed -i "s/expose_php = On/expose_php = Off/g" /usr/local/etc/php-fpm.conf
fi

# Pass real-ip to logs when behind ELB, etc
if [[ "$REAL_IP_HEADER" == "1" ]] ; then
  echo "Activating NGINX real_ip_header"
  sed -i "s/#real_ip_header X-Forwarded-For;/real_ip_header X-Forwarded-For;/" /etc/nginx/sites-available/default.conf
  sed -i "s/#set_real_ip_from/set_real_ip_from/" /etc/nginx/sites-available/default.conf
  if [ ! -z "$REAL_IP_FROM" ]; then
    echo "Chaning NGINX set_real_ip_from to ${REAL_IP_FROM}"
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
  echo "Downloading GeoIP databases"
  /etc/periodic/monthly/geoip 

  echo "Activating GeoIP NGINX configurations"
  sed -i "s/# load_module \/etc\/nginx\/modules\/ngx_http_geoip2_module.so;/load_module \/etc\/nginx\/modules\/ngx_http_geoip2_module.so;/" /etc/nginx/nginx.conf
  sed -i "s/# include \/etc\/nginx\/globals\/geoip.inc;/include \/etc\/nginx\/globals\/geoip.inc;/" /etc/nginx/nginx.conf
  sed -i "s/#fastcgi_param COUNTRY_CODE/fastcgi_param COUNTRY_CODE/" /etc/nginx/fastcgi_params
  sed -i "s/#fastcgi_param COUNTRY_NAME/fastcgi_param COUNTRY_NAME/" /etc/nginx/fastcgi_params
  sed -i "s/#fastcgi_param CITY_NAME/fastcgi_param CITY_NAME/" /etc/nginx/fastcgi_params
fi 

# Set the desired timezone
apk add --no-cache tzdata --virtual .tzdata 
if [ -z "$TIMEZONE" ]; then 
  TIMEZONE=UTC
fi 
echo "Changing PHP timezone to ${TIMEZONE}"

echo date.timezone=$TIMEZONE > /usr/local/etc/php/conf.d/timezone.ini
echo "Changins server timezone to ${TIMEZONE}"

cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime

echo $TIMEZONE > /etc/timezone 
apk del .tzdata 

# Display errors in docker logs
if [ ! -z "$PHP_ERRORS_STDERR" ]; then
  echo "Altering PHP logging to be redirected to docker logs"
  echo "log_errors = On" >> /usr/local/etc/php/conf.d/docker-vars.ini
  echo "error_log = /dev/stderr" >> /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
  echo "Altering PHP memory_limit to ${PHP_MEM_LIMIT}"
  sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
  echo "Altering PHP post_max_size to ${PHP_POST_MAX_SIZE}"
  sed -i "s/post_max_size = 100M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
  echo "Altering PHP upload_max_filesize to ${PHP_UPLOAD_MAX_FILESIZE}"
  sed -i "s/upload_max_filesize = 100M/upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the max_execution_time
if [ ! -z "$PHP_MAX_EXECUTION_TIME" ]; then
  echo "Altering PHP max_execution_time to ${PHP_MAX_EXECUTION_TIME}"
  sed -i "s/max_execution_time = 30/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/g" /usr/local/etc/php/conf.d/docker-vars.ini

  echo "Altering NGINX fastcgi_read_timeout to ${PHP_MAX_EXECUTION_TIME}"
  sed -i "s/fastcgi_read_timeout 10m;/fastcgi_read_timeout ${PHP_MAX_EXECUTION_TIME}s;/g" /etc/nginx/globals/grav.inc
else
  echo "Altering NGINX fastcgi_read_timeout to 30"
  sed -i "s/fastcgi_read_timeout 10m;/fastcgi_read_timeout 30s;/g" /etc/nginx/globals/grav.inc
fi

# Change numerical user id to match filesystem mount
if [ ! -z "$PUID" ]; then
  if [ -z "$PGID" ]; then
    PGID=${PUID}
  fi

  echo "Altering nginx uid to ${PUID}"
  usermod -u $PUID nginx

  echo "Altering nginx gid to ${PGID}"
  groupmod -g $PGID nginx
fi

# enable multisite
if [[ ! -z "$MULTISITE" ]]; then 
  if [[ "$MULTISITE" == "subdomain" ]]; then 
    echo "Enabling multisite subdomain setup"
    mv /usr/local/lib/grav/setup_subdomain.php ${WEBROOT}/setup.php 
  fi 
  if [[ "$MULTISITE" == "subdirectory" ]]; then  
    echo "Enabling multisite subdirectory setup"
    mv /usr/local/lib/grav/setup_subdirectory.php ${WEBROOT}/setup.php 
  fi 
fi 

# enable NAXSI firewall
if [[ "$NAXSI" == "1" ]]; then
  echo "Activating NAXSI"
  sed -i "s/# include \/etc\/nginx\/globals\/naxsi-site.rules/include \/etc\/nginx\/globals\/naxsi-site.rules/g" /etc/nginx/globals/grav.inc
fi

# enable PageSpeed module
if [[ "$PAGESPEED" == "1" ]]; then
  echo "Activating PageSpeed"
  sed -i "s/# include \/etc\/nginx\/globals\/pagespeed.rules/include \/etc\/nginx\/globals\/pagespeed.rules/g" /etc/nginx/globals/grav.inc
fi

# enable fastcgi cache
if [[ "$FASTCGI_CACHE" == "1" ]]; then
  echo "Activating FastCGI caching"
  sed -i "s/# include \/etc\/nginx\/globals\/fastcgi_cache.inc/include \/etc\/nginx\/globals\/fastcgi_cache.inc/g" /etc/nginx/globals/grav.inc
fi

# enable NGINX debug headers
if [[ "$NGINX_DEBUG_HEADERS" == "1" ]]; then
  echo "Activating nginx debug headers"
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
      echo "Running letsencrypt-renew"
      /usr/bin/letsencrypt-renew
    else
      echo "Running letsencrypt-setup"
      /usr/bin/letsencrypt-setup
    fi
  fi

  if [[ "$SSL_SELF_SIGNED" == "1" ]]; then 
    /usr/bin/create_self_signed &
  fi 

  if [[ -n "$SSL_CERT" ]] && [[ -n "$SSL_KEY" ]]; then 
    /usr/bin/set_custom_ssl &
  fi 

  echo "Adding domain to default SSL config"
  sed -i "s/##DOMAIN##/${DOMAIN}/g" /etc/nginx/sites-available/default-ssl.conf;

  echo "make sure NGINX is stopped"
  /usr/sbin/nginx -s stop;
fi

# if there is plugins then install each
if [ ${#PLUGINS[@]} -gt 0 ]; then 
  PLUGINS="${PLUGINS},error,markdown-notices,problems"
  IFS=',';
  for plugin in $PLUGINS; do 
    echo "Installing plugin ${plugin}"
    ${WEBROOT}/bin/gpm install -n $plugin;
  done 
  IFS=' ';
fi 

# if theme specified then install 
if [ -n "$THEME" ]; then 
  echo "Installing theme ${THEME}"
  ${WEBROOT}/bin/gpm install -n $THEME;
fi 

# Set custom admin URI
if [[ -n "$GRAV_ADMIN" ]]; then 
  echo "Setting admin URI in nginx grav config"
  sed -i "s#request_uri ~ /admin#request_uri ~ /${GRAV_ADMIN}#g" /etc/nginx/globals/grav.inc
  if [[ ! -f "${WEBROOT}/user/config/plugins/admin.yaml" ]]; then 
    if [[ ! -f "${WEBROOT}/user/plugins/admin/admin.yaml" ]]; then 
      echo "Installing admin plugin"
      ${WEBROOT}/bin/gpm install -n admin 
    fi 
    echo "Copying admin.yaml to config/plugins directory"
    mkdir -p ${WEBROOT}/user/config/plugins
    cp ${WEBROOT}/user/plugins/admin/admin.yaml ${WEBROOT}/user/config/plugins/admin.yaml
  fi 
  echo "Changing admin URL in "
  sed -ri "s#route:.*#route: '/${GRAV_ADMIN}'#" ${WEBROOT}/user/config/plugins/admin.yaml
fi 

# Run SMTP server to send mail
if [[ "$EMAIL_SERVER" == "1" ]]; then 

  echo "Installing Postfix"
  apk add --no-cache postfix 

  echo "Adding Postfix to supervisord config"
  cat <<EOF >> /etc/supervisord.conf
[program:postfix]
process_name  = master
directory	    = /etc/postfix
command		    = /usr/sbin/postfix -c /etc/postfix start
startsecs	    = 0
autorestart   = false
EOF
fi 

if [[ "$ENABLE_SASS" == "1" ]]; then
  apk add npm
  npm install -g sass
fi 

# Run SMTP server to send mail
if [[ "$GIT_PUSH" == "1" ]] || [[ "$FASTCGI_CACHE" == "1" ]]; then 

  commands=""
  if [[ "$GIT_PUSH" == "1" ]]; then 
    commands="/usr/bin/push;"
  fi
  if [[ "$FASTCGI_CACHE" == "1" ]]; then 
    commands="${commands} /usr/bin/flush_nginx_cache;"
  fi

  echo "Installing inotify-tools"
  apk add --no-cache inotify-tools

  echo "Adding inotifywait command to supervisord config"
  cat <<EOF >> /etc/supervisord.conf

[program:git-push]
command=bash -c 'while inotifywait -q -r -e create,delete,modify,move,attrib --exclude "/data/*" ${WEBROOT}/user/; do ${commands} done'
stdout_logfile	= /dev/stdout
stderr_logfile	= /dev/stderr
autorestart     = true
EOF
fi 

# Unless KEEP_NGINX_SRC set remove the NGINX source code
if [ -z "$KEEP_NGINX_SRC" ]; then 
  echo "Removing NGINX source code"
  rm -rf /usr/src/nginx-$NGINX_VERSION &
fi 

# reset file permissions
echo "Changing file ownership";
find $WEBROOT /var/www/errors ! -user nginx -exec chown nginx.nginx {} + &

echo "Changing directory permissions";
find $WEBROOT -type d -exec chmod 755 {} + &

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
