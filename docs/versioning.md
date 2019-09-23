## Versioning
We are now introducing versioning so users can stick to specific versions of software. As we are dealing with three upstream sources (nginx, php and alpine) plus our own scripts this all gets a little complex, but this document will provide a definitive source of tags and versions.

### Current versions and tags

The latest tag will always follow the master branch in git. the other versions will have releases attached.

>This follows the format MAJOR.MINOR.PATCH (eg, 1.2.6)
>
- MAJOR version changes to NGINX, PHP-FPM, Alpine, Grav or potential breaking feature changes
- MINOR version changes to NGINX, PHP-FPM, Grav or scripts that are still backwards-compatible with previous versions
- PATCH version minor changes and bug fixes