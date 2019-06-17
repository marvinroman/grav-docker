geoip2 /etc/maxmind-country.mmdb {
    auto_reload 5h;
    $geoip2_metadata_country_build metadata build_epoch;
    $geoip2_data_country_code default=US source=$remote_addr country iso_code;
    $geoip2_data_country_name country names en;
}

geoip2 /etc/maxmind-city.mmdb {
    $geoip2_data_city_name default=London city names en;
}