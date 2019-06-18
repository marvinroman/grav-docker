## Docker Compose Guide
This guide will show you how to make a quick and easy docker compose file to get your container running using the compose tool.


### Creating a compose file
Create a docker-compose.yml file with the following contents:

```
version: '3'
services:
  site:
    image: magemonkey/grav-docker:latest
    ports:
      - "80:80"
    environment:
      - "ERRORS=1"
      - "DOMAIN=localhost"
      - "GIT_EMAIL=gituser@email.com"
      - "GIT_NAME=your name"
      - "PUID=1000" # Change to UID of your current computer user
      - "FASTCGI_CACHE=0"
      - "MAX_EXECUTION_TIME=120"
      - "PHP_MEM_LIMIT=256"
      - "USE_GEOIP=1"
      - "NGINX_DEBUG_HEADERS=1"
      - "GIT_USE_SSH=1"
      - "SSH_KEY=LONG_BASE64_ENCODED_KEY"
      - "GIT_REPO=git@gitlab.com:username/reponame.git"
      - "GIT_BRANCH=master"
      - "GRAV_ADMIN=admin"
      - "GIT_PUSH=1"
      - "TIMEZONE=America/Los_Angeles"
    volumes:
      - "user:/var/www/html/user:cached"
      - "backup:/var/www/html/backup:cached"
volumes:
  backup: 
  user: 
```
You can of course expand on this and add volumes, or extra environment parameters as defined in the [config flags](../config_flags.md) documentation.

### Running
To start the container simply run: ```docker-compose up -d```

### Clean Up
To shut down the compose network and container runt he following command: ```docker-compose down```
