set $skip_cache 0;
if ($request_method = POST) { set $skip_cache 1; }

# include /etc/nginx/globals/pagespeed.rules;

error_page 400 401 403 /40x.html;
error_page 404 /404.html;
error_page 500 /50x.html;

location ~ ^/(sad\.svg|ban\.svg|50x\.html|40x\.html|404\.html)$ {
    root  /var/www/errors;
    expires 1M;
    access_log off;
    add_header Cache-Control "public";
}

location / {
    # include /etc/nginx/globals/naxsi-site.rules;
    absolute_redirect off;
    try_files $uri $uri/ /index.php?$query_string;
}

# pass the PHP scripts to FastCGI server listening on socket
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass unix:/run/php-fpm.sock;
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param SCRIPT_NAME $fastcgi_script_name;
    fastcgi_index index.php;
    include fastcgi_params;

    # include /etc/nginx/globals/fastcgi_cache.inc;
    # include /etc/nginx/globals/debug.inc;

    fastcgi_intercept_errors on;
    # fastcgi_read_timeout should match max_execution_time in php.ini
    fastcgi_read_timeout 10m;
    fastcgi_param SERVER_NAME $host;
    fastcgi_param HTTPS $fcgi_https;
}

# Expire rules for static content
# Feed
location ~* \.(?:rss|atom|cache)$ {
    expires 1h;
}

# Media: images, icons, video, audio, HTC
location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
    expires 1M;
    access_log off;
    add_header Cache-Control "public";
}

# Prevent clients from accessing hidden files (starting with a dot)
# This is particularly important if you store .htpasswd files in the site hierarchy
# Access to `/.well-known/` is allowed.
# https://www.mnot.net/blog/2010/04/07/well-known
# https://tools.ietf.org/html/rfc5785
location ~* /\.(?!well-known\/) {
    deny all;
}

# Prevent clients from accessing to backup/config/source files
location ~* (?:\.(?:bak|conf|dist|fla|in[ci]|log|psd|sh|sql|sw[op])|~)$ {
    deny all;
}

## Begin - Security
# deny all direct access for these folders
location ~* /(\.git|cache|bin|logs|backup|tests)/.*$ { return 403; }
# deny running scripts inside core system folders
location ~* /(system|vendor)/.*\.(txt|xml|md|html|yaml|yml|php|pl|py|cgi|twig|sh|bat)$ { return 403; }
# deny running scripts inside user folder
location ~* /user/.*\.(txt|md|yaml|yml|php|pl|py|cgi|twig|sh|bat)$ { return 403; }
# deny access to specific files in the root folder
location ~ /(LICENSE\.txt|composer\.lock|composer\.json|nginx\.conf|web\.config|htaccess\.txt|\.htaccess|CHANGELOG\.md|CODE_OF_CONDUCT\.md|CONTRIBUTING\.md|README\.md|codeception\.yml) { return 403; }
## End - Security


## provide a health check endpoint
location /healthcheck {
    access_log off;
    stub_status     on;
    keepalive_timeout 0;    # Disable HTTP keepalive
    return 200;
}

location ~ ^/(fpmstatus|ping)$ {
    access_log off;
    stub_status     on;
    keepalive_timeout 0;    # Disable HTTP keepalive
    allow 127.0.0.1;
    allow all;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
    fastcgi_pass unix:/run/php-fpm.sock;
}
