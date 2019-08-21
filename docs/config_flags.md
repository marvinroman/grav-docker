## Available Configuration Parameters
The following flags are a list of all the currently supported options that can be changed by passing in the variables to docker with the -e flag.

### GIT 

Name | Description
------------------------- |----------------------------------------------------------------------------------------------------------------
GIT_PUSH | Set to 1 to automatically push to repo on changes in `/user` directory  
GIT_USE_SSH | Set this to 1 if you want to use git over SSH (instead of HTTP), useful if you want to use Bitbucket instead of GitHub  
GIT_EMAIL | Set your email for code pushing (required for git to work)  
GIT_NAME | Set your name for code pushing (required for git to work)  
GIT_REPO | URL to the repository containing your source code. If you are using a personal token, this is the https URL without `https://` (e.g `github.com/project/`). For ssh prepend with `git@` (e.g `git@github.com/project.git`)  
GIT_BRANCH | Select a specific branch (optional)  
GIT_TAG | Specify a specific git tag (optional)  
GIT_COMMIT | Specify a specific git commit (optional)  
SSH_KEY | Private SSH deploy key for your repository base64 encoded (requires write permissions for pushing)  
GIT_PERSONAL_TOKEN | Personal access token for your git account (required for HTTPS git access)  
GIT_USERNAME | Git username for use with personal tokens. (required for HTTPS git access)  

## NGINX 
Name | Description  
------------------------- | ----------------------------------------------------------------------------------------------------------------  
HIDE_NGINX_HEADERS | Disable by setting to 0, default behaviour is to hide nginx + php version in headers
DOMAIN | Set domain name for Lets Encrypt scripts
REAL_IP_HEADER | set to 1 to enable real ip support in the logs
REAL_IP_FROM | set to your CIDR block for real ip in logs
SSL_ENABLED | Set to 1 to enable the SSL configuration
SSL_LETS_ENCRYPT | Set to 1 to automate SSL creation using Let's Encrypt
NGINX_DEBUG_HEADERS | Set to 1 to enable the sending of debug headers to the browser
USE_GEOIP | Set to 1 for NGINX to pass COUNTRY_CODE, COUNTRY_NAME & CITY_NAME to PHP
FASTCGI_CACHE | Set to 1 to enable fastcgi caching
KEEP_NGINX_SRC | Set if you want to keep NGINX source code for testing new compiling  
NAXSI Set to 1 to enable NAXSI web firewall @TODO not yet implemented
PAGESPEED | Set to 1 to enable Pagespeed module @TODO not yet implemented

## PHP 
Name | Description  
------------------------- | ----------------------------------------------------------------------------------------------------------------  
ERRORS | Set to 1 to display PHP Errors in the browser
PHP_MEM_LIMIT | Set higher PHP memory limit, default is 128 Mb
PHP_POST_MAX_SIZE | Set a larger post_max_size, default is 100 Mb
PHP_UPLOAD_MAX_FILESIZE | Set a larger upload_max_filesize, default is 100 Mb
PHP_ERRORS_STDERR | Send php logs to docker logs
PHP_MAX_EXECUTION_TIME | Set php max_execution_time 

## GRAV 
Name | Description  
------------------------- | ----------------------------------------------------------------------------------------------------------------  
WEBROOT | Change the default webroot directory from `/var/www/html` to your own setting
PREP_USER_VOLUME | Copy backup of user directory to mounted user directory
PLUGINS | Comma separated list of plugins you want installed
THEME | Public theme you want installed from the Grav site
GRAV_ADMIN | Set to URI that you want to replace `/admin`  

### SYSTEM

Name | Description
------------------------- |----------------------------------------------------------------------------------------------------------------
PUID | Set to UserID you want to use for nginx (helps permissions when using local volume)
PGID | Set to GroupId you want to use for nginx (helps permissions when using local volume)
TIMEZONE | Set container timezone
EMAIL_SERVER | Set to 1 to install and enable Postfix server to allow sending email

# DEVELOPMENT 

Name | Description
------------------------- |----------------------------------------------------------------------------------------------------------------
ENABLE_SASS | Set to 1 to install SASS in order to compile SASS