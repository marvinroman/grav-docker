add_header X-IP             $remote_addr;
add_header X-Cache          $upstream_cache_status;
add_header X-Skipcache      $skip_cache;
# add_header X-bot            $is_bot;
