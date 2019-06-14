FROM magemonkey/grav-docker:latest
LABEL maintainer="Marvin Roman <marvinroman@protonmail.com"
LABEL repository="https://github.com/hibbitts-design/grav-skeleton-learn2-with-git-sync"
LABEL version="v1.5.2"

ENV VERSION v1.5.2
ENV WEBROOT /var/www/html
ENV SKELETON grav-skeleton-learn2-with-git-sync-site

# Install skeleton
WORKDIR /var/www 
RUN rm -rf ${WEBROOT}
RUN curl -fSL "https://github.com/hibbitts-design/grav-skeleton-learn2-with-git-sync/releases/download/${VERSION}/${SKELETON}.zip" -o ${SKELETON}.zip 
RUN unzip -q ${SKELETON}.zip
RUN mv ${SKELETON} html 
RUN rm -f ${SKELETON}.zip
RUN mkdir -p /var/lib/grav/user

# Create copy of user directory to copy for mounted volumes
RUN rsync -a --del \
    /var/www/html/user/ \
    /var/lib/grav/user 

# Change working directory back to web root
WORKDIR ${WEBROOT}

# Cleanup
RUN rm -f \
    .dependencies \
    .editorconfig \
    .htaccess \
    .travis.yml \
    CHANGELOG.md \
    CODE_OF_CONDUCT.md \
    CONTRIBUTING.md \
    LICENSE.txt \
    README.md \
    codeception.yml
RUN chown -R nginx.nginx ${WEBROOT}