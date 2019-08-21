FROM php:7.3.6-fpm-alpine3.9

ENV php_conf /usr/local/etc/php-fpm.conf
ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_vars /usr/local/etc/php/conf.d/docker-vars.ini

ENV NGINX_VERSION 1.16.1
ENV FRICKLE_MODULE_VERSION=2.3
ENV LUA_MODULE_VERSION 0.10.14
ENV DEVEL_KIT_MODULE_VERSION 0.3.0
ENV LIBMAXMINDDB_VERSION 1.3.2
ENV GEOIP2_MODULE_VERSION 3.2
ENV LUAJIT_LIB=/usr/lib
ENV LUAJIT_INC=/usr/include/luajit-2.1
ENV GRAV_VERSION 1.6.15

# build deps
ENV BUILD_DEPS "autoconf \
  augeas-dev \
  gcc \
  gd-dev \
  geoip-dev \
  gnupg \
  libc-dev \
  libffi-dev \
  libressl-dev \
  libxslt-dev \
  libzip-dev \
  linux-headers \
  luajit-dev \
  make \
  musl-dev \
  pcre-dev \
  perl-dev \
  python-dev \
  zlib-dev"

# Iconv fix see (https://github.com/docker-library/php/issues/240)
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Install PHP required extensions
ENV PHP_REQS "ctype \
  dom \
  exif \
  gd \
  iconv \
  json \
  mbstring \
  simplexml \
  xml\
  zip"
RUN apk add --no-cache --virtual .php-libs \
  curl \
  freetype \
  libjpeg-turbo \
  libpng \
  libwebp \
  libxml2 \
  libxpm \
  libzip \
  zlib

RUN apk add --no-cache --virtual .php-build-deps \
  curl-dev \
  freetype-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libwebp-dev \
  libxml2-dev \
  libxpm-dev \
  libzip-dev \
  zlib-dev

RUN docker-php-ext-configure gd \
  --with-gd \
  --with-freetype-dir=/usr/include/ \
  --with-jpeg-dir=/usr/include/ \
  --with-png-dir=/usr/include/ \
  --with-webp-dir=/usr/include/ \
  --with-xpm-dir=/usr/include/ && \
  docker-php-ext-install -j$(nproc) $PHP_REQS && \
  docker-php-ext-enable $PHP_REQS && \
  docker-php-source delete

# @TODO: compile NGINX w/NAXSI
# @TODO: compile NGINX w/pagespeed
ENV GPG_KEYS B0F4253373F8F6F510D42178520A9993A1C052F8
ENV NGINX_CONFIG "--prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --user=nginx \
  --group=nginx \
  --with-debug \
  --with-http_ssl_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_stub_status_module \
  --with-http_auth_request_module \
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_perl_module=dynamic \
  --with-threads \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-http_slice_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-compat \
  --with-file-aio \
  --with-http_v2_module \
  --add-dynamic-module=/usr/src/ngx_devel_kit-$DEVEL_KIT_MODULE_VERSION \
  --add-dynamic-module=/usr/src/lua-nginx-module-$LUA_MODULE_VERSION \
  --add-dynamic-module=/usr/src/ngx_http_geoip2_module-$GEOIP2_MODULE_VERSION \
  --add-dynamic-module=/usr/src/ngx_cache_purge-$FRICKLE_MODULE_VERSION"

RUN addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

RUN apk add --no-cache --virtual .build-deps $BUILD_DEPS

WORKDIR /tmp 
RUN curl -fSL https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VERSION}/libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz -o libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz \
  && tar -zxf libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz \
  && cd libmaxminddb-${LIBMAXMINDDB_VERSION} \
  && ./configure \
  && make \
  && make install

WORKDIR /tmp 
RUN curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
  && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
  && curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v$DEVEL_KIT_MODULE_VERSION.tar.gz -o ndk.tar.gz \
  && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$LUA_MODULE_VERSION.tar.gz -o lua.tar.gz \
  && curl -fSL https://github.com/FRiCKLE/ngx_cache_purge/archive/${FRICKLE_MODULE_VERSION}.tar.gz -o ngx_cache_purge.tar.gz \
  && curl -fSL https://github.com/leev/ngx_http_geoip2_module/archive/${GEOIP2_MODULE_VERSION}.tar.gz -o ngx_http_geoip2_module.tar.gz

RUN export GNUPGHOME="$(mktemp -d)" \
  && found=''; \
  for server in \
  ha.pool.sks-keyservers.net \
  hkp://keyserver.ubuntu.com:80 \
  hkp://p80.pool.sks-keyservers.net:80 \
  pgp.mit.edu \
  ; do \
  echo "Fetching GPG key $GPG_KEYS from $server"; \
  gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
  done; \
  test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
  gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz

RUN mkdir -p /usr/src \
  && tar -zxC /usr/src -f nginx.tar.gz \
  && tar -zxC /usr/src -f ndk.tar.gz \
  && tar -zxC /usr/src -f lua.tar.gz \
  && tar -zxC /usr/src -f ngx_cache_purge.tar.gz \
  && tar -zxC /usr/src -f ngx_http_geoip2_module.tar.gz \
  && rm nginx.tar.gz ndk.tar.gz lua.tar.gz ngx_cache_purge.tar.gz ngx_http_geoip2_module.tar.gz

WORKDIR /usr/src/nginx-$NGINX_VERSION

RUN ./configure $NGINX_CONFIG \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && rm -rf /etc/nginx/html/ \
  && mkdir /etc/nginx/conf.d/ \
  && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx* \
  && strip /usr/lib/nginx/modules/*.so \
  \
  # Bring in gettext so we can get `envsubst`, then throw
  # the rest away. To do this, we need to install `gettext`
  # then move `envsubst` out of the way so `gettext` can
  # be deleted completely, then move `envsubst` back.
  && apk add --no-cache --virtual .gettext gettext \
  && mv /usr/bin/envsubst /tmp/ \
  \
  && runDeps="$( \
  scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
  | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
  | sort -u \
  | xargs -r apk info --installed \
  | sort -u \
  )" \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  && mv /tmp/envsubst /usr/local/bin/ 

# Install system dependencies
RUN apk add --no-cache --virtual .sys-deps \
  bash \
  git \
  openssh-client \
  rsync \
  shadow \
  su-exec \
  supervisor && \
  mkdir -p /run/nginx && \
  mkdir -p /var/log/supervisor

# Install certbot
RUN apk add --no-cache certbot-nginx && \
  mkdir -p /etc/letsencrypt/webrootauth

# Cleanup 
RUN apk del .build-deps && \
  apk del .gettext && \
  apk del .php-build-deps

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ && \
  mkdir -p /etc/nginx/sites-enabled/ && \
  mkdir -p /etc/nginx/ssl/ && \
  rm -Rf /var/www/* && \
  mkdir /var/www/html/ 
COPY etc /etc

# tweak php-fpm config
RUN echo "cgi.fix_pathinfo=0" > ${php_vars} &&\
  echo "upload_max_filesize = 100M"  >> ${php_vars} &&\
  echo "post_max_size = 100M"  >> ${php_vars} &&\
  echo "variables_order = \"EGPCS\""  >> ${php_vars} && \
  echo "memory_limit = 128M"  >> ${php_vars} && \
  echo "max_execution_time = 30" >> ${php_vars} && \
  echo "log_errors = On" >> ${php_vars} && \
  echo "error_reporting = E_ALL" >> ${php_vars} && \
  echo "error_log = /var/www/html/logs/php-errors.log" >> ${php_vars} && \
  sed -i \
  -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
  -e "s/pm.max_children = 5/pm.max_children = 4/g" \
  -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
  -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
  -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
  -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
  -e "s/user = www-data/user = nginx/g" \
  -e "s/group = www-data/group = nginx/g" \
  -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
  -e "s/;listen.owner = www-data/listen.owner = nginx/g" \
  -e "s/;listen.group = www-data/listen.group = nginx/g" \
  -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
  -e "s/^;clear_env = no$/clear_env = no/" \
  ${fpm_conf}
#    ln -s /etc/php7/php.ini /etc/php7/conf.d/php.ini && \
#    find /etc/php7/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

COPY usr /usr 
RUN find /usr/bin -type f -exec chmod a+x {} +

# Install Grav 
RUN /usr/bin/install-grav 
WORKDIR /var/www/html 
COPY favicon.ico /var/www/html/favicon.ico

# Prep user copy for mounted user directories
RUN mkdir -p /var/lib/grav/user
RUN rsync -a --del \
  /var/www/html/user/ \
  /var/lib/grav/user 

# Copy in NGINX error pages
ADD errors/ /var/www/errors
RUN chown -R nginx.nginx /var/www/errors

# Make cron scheduler script 
RUN (crontab -l; echo "* * * * * run-parts /etc/periodic/everymin") | crontab -
RUN find /etc/periodic -type f -exec chmod +x {} +

# Add Start Script
ADD scripts/start.sh /start.sh
RUN chmod a+x /start.sh

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

LABEL maintainer="Marvin Roman <marvinroman@protonmail.com>"
LABEL version="0.1.5"

EXPOSE 443 80
CMD ["/start.sh"]
