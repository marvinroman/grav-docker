fastcgi_cache           site;
fastcgi_cache_methods   GET HEAD;
fastcgi_cache_valid     200 48h;
fastcgi_cache_valid     301 404 24h;
fastcgi_cache_valid     302 6h;
fastcgi_cache_bypass    $skip_cache;
fastcgi_no_cache        $skip_cache;
fastcgi_ignore_headers  X-Accel-Expires Expires Cache-Control Set-Cookie;
