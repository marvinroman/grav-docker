![pipeline status](https://gitlab.com/marvinroman/grav-docker/badges/master/pipeline.svg)
![docker hub](https://img.shields.io/docker/pulls/magemonkey/grav-docker.svg?style=flat-square)
![docker hub](https://img.shields.io/docker/stars/magemonkey/grav-docker.svg?style=flat-square)

## Alpha/Experimental Status
Consider this Docker to still be an Alpha experimental release. Don't use in production until you have tested thoroughly.

## Overview
This is a Docker running NGINX & PHP-FPM. Pre-installed with the latest version of the [Grav CMS](https://getgrav.org/). With 35+ configuration variables it can automate the installation of plugins, themes, pulling your site's repository, FastCGI caching, SSL generation and more. 
Looking for testers & contributors to bring this project out of Alpha. If you have any issues or suggestions please open an issue or pull request on the [GitLab Page](https://gitlab.com/marvinroman/grav-docker).

### Versions
Docker Tag | Git Release | Grav Version | Nginx Version | PHP Version | Alpine Version
-----|-------|-----|------|--------|--------
latest/0.1 | Master Branch | 1.6.10 | 1.16.0 | 7.3.6 | 3.9
skeleton-open-publishing-space-v1.5.5 | Master Branch | 1.6.10 | 1.16.0 | 7.3.6 | 3.9
skeleton-learn2-with-git-sync-v1.5.2 | Master Branch | 1.6.10 | 1.16.0 | 7.3.6 | 3.9
develop | Develop Branch | 1.6.10 | 1.16.0 | 7.3.6 | 3.9

### DockerHub Link
- [https://hub.docker.com/r/magemonkey/grav-docker](https://hub.docker.com/r/magemonkey/grav-docker)

## Quick Start
To pull from docker hub:
```
docker pull magemonkey/grav-docker:latest
```
## Grav Skeletons
A Grav skeleton is an all-in-one package containing the core Grav system plus sample pages, plugins, configuration. These packages are a great way to get started with Grav.
### Open Publishing Space
Open Publishing (Blogging) Space uses a customized version of the Quark theme to support the creation, sharing and collaborative editing of Markdown-based blogs. Includes Admin Panel and Git Sync plugins.
[Repo](https://github.com/hibbitts-design/grav-skeleton-open-publishing-space) | [Demo](https://demo.hibbittsdesign.org/grav-open-publishing-quark/)

Try it out. 
```
docker run --rm -d -p 80:80 magemonkey/grav-docker:skeleton-open-publishing-space-v1.5.5
```  
Browse to [localhost](http://localhost).

### Learn2 with Git Sync Site
Learn2 with Git Sync, a sample documentation site using the Learn2 Git Sync theme. Includes Admin Panel and TNTSearch plugins along with RSS/Atom Feeds.
[Repo](https://github.com/hibbitts-design/grav-skeleton-learn2-with-git-sync) | [Demo](https://demo.hibbittsdesign.org/grav-learn2-git-sync/)

Try it out. 
```
docker run --rm -d -p 80:80 magemonkey/grav-docker:skeleton-learn2-with-git-sync-v1.5.2
```  
Browse to [localhost](http://localhost).

### Running
To simply run the container:
```
docker run --rm -d magemonkey/grav-docker:<version>
```
To dynamically pull code from git when starting:
```
docker run -d -e 'GIT_EMAIL=email_address' -e 'GIT_NAME=full_name' -e 'GIT_USERNAME=git_username' -e 'GIT_REPO=github.com/project' -e 'GIT_PERSONAL_TOKEN=<long_token_string_here>' magemonkey/grav-docker:<version>
```

You can then browse to ```http://<DOCKER_HOST>``` to view the default install files. To find your ```DOCKER_HOST``` use the ```docker inspect``` to get the IP address (normally 172.17.0.2)

For more detailed examples and explanations please refer to the documentation.
## Documentation

- [Building from source](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/building.md)
- [Config Flags](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/config_flags.md)
- [Git Auth](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/git_auth.md)
  - [Personal Access token](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/git_auth.md#personal-access-token)
  - [SSH Keys](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/git_auth.md#ssh-keys)
- [Git Commands](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/git_commands.md)
 - [Push](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/git_commands.md#push-code-to-git)
 - [Pull](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/git_commands.md#pull-code-from-git-refresh)
- [Repository layout / webroot](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/repo_layout.md)
 - [webroot](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/repo_layout.md#src--webroot)
- [User / Group Identifiers](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/UID_GID_Mapping.md)
- [Custom Nginx Config files](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/nginx_configs.md)
 - [REAL IP / X-Forwarded-For Headers](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/nginx_configs.md#real-ip--x-forwarded-for-headers)
- [Scripting and Templating](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/scripting_templating.md)
 - [Environment Variables](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/scripting_templating.md#using-environment-variables--templating)
- [Lets Encrypt Support](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/lets_encrypt.md)
 - [Setup](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/lets_encrypt.md#setup)
 - [Renewal](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/lets_encrypt.md#renewal)
- [PHP Modules](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/php_modules.md)
- [Xdebug](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/xdebug.md)
- [Logging and Errors](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/logs.md)

## Guides
- [Running in Kubernetes](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/guides/kubernetes.md)
- [Using Docker Compose](https://gitlab.com/marvinroman/grav-docker/blob/master/docs/guides/docker_compose.md)
