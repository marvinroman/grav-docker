#!/bin/bash

# Disable Strict Host checking for non interactive git clones

mkdir -p -m 0700 /root/.ssh
# Prevent config files from being filled to infinity by force of stop and restart the container
echo "" > /root/.ssh/config
echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

if [[ "$GIT_USE_SSH" == "1" ]] ; then
  echo -e "Host *\n\tUser git\n\tIdentityFile /root/.ssh/id_rsa\n\n" >> /root/.ssh/config
  cat /root/.ssh/config

  if [ -z "$SSH_KEY" ]; then
    echo "SSH_KEY must be set when GIT_USE_SSH=1"
    exit 1
  fi
fi

if [ ! -z "$SSH_KEY" ]; then
    echo $SSH_KEY > /root/.ssh/id_rsa.base64
    base64 -d /root/.ssh/id_rsa.base64 > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
fi 

# Set custom WEBROOT
if [ ! -z "$WEBROOT" ]; then
  echo "Changing root from /var/www/html to ${WEBROOT}";
  sed -i "s#root ${WEBROOT};#root ${WEBROOT};#g" /etc/nginx/sites-*/*.conf;
else
  WEBROOT=/var/www/html;
fi

# Setup git variables
if [ ! -z "$GIT_EMAIL" ]; then
 git config --global user.email "$GIT_EMAIL"
fi
if [ ! -z "$GIT_NAME" ]; then
 git config --global user.name "$GIT_NAME"
 git config --global push.default simple
fi

# Prepare user volume if mounted
if [[ "$PREP_USER_VOLUME" == "1" ]]; then 
  # copy backed up user directory to mounted user volume
  rsync -a /var/lib/grav/user/ $WEBROOT/user
fi 

# remove copy of grav user directory from container
rm -rf /var/lib/grav 

pull_repo() {

  # Overwrite default git variables with repo specific variables
  if [ -n "$GIT_VARIABLES" ]; then 
    for VARS in $GIT_VARIABLES; do 
      IFS=':' read -ra VARS <<< "$VARS"
      VAR0=${VARS[0]}
      VAR1=${VARS[1]}
      declare "${VAR1}"="${!VAR0}"
      echo "${VAR1}: ${!VAR1}"
      IFS=' '
    done
  fi 

  # Pull down code from git for our site!
  if [ ! -z "$GIT_REPO" ]; then

    # Set branch to master if not set
    if [ -z "$GIT_BRANCH" ]; then
      GIT_BRANCH="master"
    fi

    if [ ! -z "$GIT_USERNAME" ] && [ ! -z "$GIT_PERSONAL_TOKEN" ] && [ "$GIT_USE_SSH" != "1" ]; then
      GIT_REPO=" https://${GIT_USERNAME}:${GIT_PERSONAL_TOKEN}@${GIT_REPO}"
    fi

    # Dont pull code down if the .git folder exists
    if [ -d "${GIT_DIR}/.git" ]; then
      cd ${GIT_DIR}
      git remote add origin ${GIT_REPO} || git remote set-url origin ${GIT_REPO}
      git pull origin ${GIT_BRANCH} || exit 1
      git checkout ${GIT_BRANCH} || exit 1
      git submodule update --recursive || exit 1
    else 
      rm -rf ${GIT_DIR}
      git clone ${GIT_BARE} -b ${GIT_BRANCH} ${GIT_REPO} ${GIT_DIR} || exit 1
    fi

    cd ${GIT_DIR}
    if [ ! -z "$GIT_TAG" ]; then
      git checkout ${GIT_TAG} || exit 1
    fi
    if [ ! -z "$GIT_COMMIT" ]; then
      git checkout ${GIT_COMMIT} || exit 1
    fi
  fi
}

GIT_DIR=$WEBROOT
pull_repo

# Pull /user directory repo
declare -a GIT_VARIABLES  
GIT_VARIABLES=("USRDIR_GIT_REPO:GIT_REPO" "USRDIR_GIT_USERNAME:GIT_USERNAME" "USRDIR_GIT_PERSONAL_TOKEN:GIT_PERSONAL_TOKEN" "USRDIR_GIT_BRANCH:GIT_BRANCH" "USRDIR_GIT_TAG:GIT_TAG" "USRDIR_GIT_COMMIT:GIT_COMMIT" "USRDIR_GIT_BARE:GIT_BARE")
GIT_DIR=${WEBROOT}/user
pull_repo

# Pull /user/pages directory repo
GIT_VARIABLES=("PGDIR_GIT_REPO:GIT_REPO" "PGDIR_GIT_USERNAME:GIT_USERNAME" "PGDIR_GIT_PERSONAL_TOKEN:GIT_PERSONAL_TOKEN" "PGDIR_GIT_BRANCH:GIT_BRANCH" "PGDIR_GIT_TAG:GIT_TAG" "PGDIR_GIT_COMMIT:GIT_COMMIT" "PGDIR_GIT_BARE:GIT_BARE")
GIT_DIR=${WEBROOT}/user/pages
pull_repo

# Pull /user/config directory repo
GIT_VARIABLES=("CDIR_GIT_REPO:GIT_REPO" "CDIR_GIT_USERNAME:GIT_USERNAME" "CDIR_GIT_PERSONAL_TOKEN:GIT_PERSONAL_TOKEN" "CDIR_GIT_BRANCH:GIT_BRANCH" "CDIR_GIT_TAG:GIT_TAG" "CDIR_GIT_COMMIT:GIT_COMMIT" "CDIR_GIT_BARE:GIT_BARE")
GIT_DIR=${WEBROOT}/user/config
pull_repo

# Pull /user/plugins directory repo
GIT_VARIABLES=("PLDIR_GIT_REPO:GIT_REPO" "PLDIR_GIT_USERNAME:GIT_USERNAME" "PLDIR_GIT_PERSONAL_TOKEN:GIT_PERSONAL_TOKEN" "PLDIR_GIT_BRANCH:GIT_BRANCH" "PLDIR_GIT_TAG:GIT_TAG" "PLDIR_GIT_COMMIT:GIT_COMMIT" "PLDIR_GIT_BARE:GIT_BARE")
GIT_DIR=${WEBROOT}/user/plugins
pull_repo

# Pull /user/themes directory repo
GIT_VARIABLES=("THDIR_GIT_REPO:GIT_REPO" "THDIR_GIT_USERNAME:GIT_USERNAME" "THDIR_GIT_PERSONAL_TOKEN:GIT_PERSONAL_TOKEN" "THDIR_GIT_BRANCH:GIT_BRANCH" "THDIR_GIT_TAG:GIT_TAG" "THDIR_GIT_COMMIT:GIT_COMMIT" "THDIR_GIT_BARE:GIT_BARE")
GIT_DIR=${WEBROOT}/user/themes
pull_repo

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

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
