fastcgi_cache           site;
fastcgi_cache_methods   GET HEAD;
fastcgi_cache_valid     200 2h;
fastcgi_cache_valid     301 404 1h;
fastcgi_cache_valid     302 30m;
fastcgi_cache_bypass    $skip_cache;
fastcgi_no_cache        $skip_cache;
