## Install PHP Modules
To install and configure extra PHP modules in this image, first of all drop into the container:
```
docker exec -it <container-name> bash
```
Then configure and install your module:
```
docker-php-ext-configure intl
docker-php-ext-install intl
```
Now restart php-fpm:
```
supervisorctl restart php-fpm
```

We may include a env var to do this in the future.

## Extensions already installed
The following are already installed and ready to use:

`docker-php-ext-`name | Description 
----|----
ctype | Check's character type/class  
curl | command line tool and library for transferring data with URLs
dom | PHP DOM manipulation library 
exif | Work with image meta data.  
gd | Image creation and manipulation library 
iconv | Character set conversion facility. (Includes alpine iconv fix)  
json | Impliments JSON data-interchange format.  
mbstring | An extension of php used to manage non-ASCII string  
openssl | Access to some of OpenSSL crypto operations.  
session | PHP session support.  
simplexml | Easily manipulate/use XML data.  
xml | PHP XML support.
zip | Transparently read and write ZIP compressed archives
