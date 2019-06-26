FROM magemonkey/grav-docker:latest
LABEL maintainer="Marvin Roman <marvinroman@protonmail.com"
LABEL repository="https://github.com/hibbitts-design/grav-skeleton-open-publishing-space"
LABEL version="v1.5.5"

ENV VERSION v1.5.5
ENV WEBROOT /var/www/html
ENV SKELETON grav-skeleton-open-publishing-space-site

# Install skeleton
WORKDIR /var/www 
RUN rm -rf ${WEBROOT}
RUN curl -fSL "https://github.com/hibbitts-design/grav-skeleton-open-publishing-space/releases/download/${VERSION}/${SKELETON}.zip" -o ${SKELETON}.zip 
RUN unzip -q ${SKELETON}.zip
RUN mv ${SKELETON} html 
RUN rm -f ${SKELETON}.zip

# Create copy of user directory to copy for mounted volumes
RUN mkdir -p /var/lib/grav/user
RUN rsync -a --del \
    /var/www/html/user/ \
    /var/lib/grav/user 

# Change working directory back to web root
WORKDIR ${WEBROOT}

# Cleanup
RUN rm -rf \
    .dependencies \
    .editorconfig \
    .htaccess \
    .travis.yml \
    CHANGELOG.md \
    CODE_OF_CONDUCT.md \
    CONTRIBUTING.md \
    LICENSE.txt \
    README.md \
    codeception.yml \
    user/.dependencies \
    user/.gitattributes \
    user/.github/ \
    user/CHANGELOG.md \
    user/LICENSE 
