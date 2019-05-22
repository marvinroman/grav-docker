# Major Search engines
if ($http_user_agent ~ (bingbot|BingPreview|msnbot-UDiscovery|Googlebot|Baiduspider|ia_archiver|Yahoo\!\ Slurp|YandexBot|Sosospider|Exabot|facebookexternalhit|TweetedTimes\ Bot) ) { set $is_bot "Y"; }
# Secondary Search Engines
if ($http_user_agent ~ (MJ12bot|msnbot|Scooter|Ask\ Jeeves|Yahoo\!\ DE\ Slurp|Mail\.RU|ichiro) ) { set $is_bot "Y"; }
# Questionable Search Engines
if ($http_user_agent ~ (Flamingo_SearchEngine|FAST-WebCrawler) ) { set $is_bot "Y"; }
# Scrapers
if ($http_user_agent ~ (Zemanta\ Aggregator|FAST\ Enterprise\ Crawler|ICCrawler|Gigabot|magpie-crawler) ) { set $is_bot "Y"; }
# Mobile
if ($http_user_agent ~ (Googlebot-Mobile) ) { set $is_bot "Y"; }
# SEO Bots
if ($http_user_agent ~ (SEO\.search\.Crawler|Seoma\.\[SEO\.Crawler\]|SEOsearch|rogerbot) ) { set $is_bot "Y"; }
# Media Bots
if ($http_user_agent ~ (Mediapartners-Google|msnbot-media|Baiduspider-image|Googlebot-Image|YandexImageResizer|Sosoimagespider|Exabot-Thumbnails|Yahoo-MMCrawler) ) { set $is_bot "Y"; }
# Specialty Bots
if ($http_user_agent ~ (AdsBot-Google|Feedly|msnbot-NewsBlogs|Feed[fF]etcher-Google|Google\ Desktop|YandexAntivirus|YandexBlogs|YandexNewslinks|YandexMetrika|YandexDirect|FeedBurner|Yahoo\!-AdCrawler|Yahoo\ Pipes|baidu\ Transcoder) ) { set $is_bot "Y"; }
# Speed Testers
if ($http_user_agent ~ (Pingdom.com_bot) ) { set $is_bot "Y"; }
#other
if ($http_user_agent ~ (MetagerBot|NG-Search|lucene\.apache\.org|NutchCVS|OmniExplorer_Bot|Seekbot|Sensis(\.com\.au)?\ Web\ Crawler|Snappy|www\.urltrends\.com|www\.tkl\.iis\.u-tokyo\.ac\.jp/~crawler|SynooBot|crawleradmin\.t-info@telekom\.de|W3\ SiteSearch\ Crawler|W3C-checklink|W3C_Validator|www\.WISEnutbot\.com|yacybot|msnbot-UDiscovery) ) { set $is_bot "Y"; }
