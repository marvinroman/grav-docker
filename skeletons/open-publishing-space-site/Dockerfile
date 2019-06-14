FROM magemonkey/grav-docker:latest
LABEL maintainer="Marvin Roman <marvinroman@protonmail.com"
LABEL repository="https://github.com/hibbitts-design/grav-skeleton-open-publishing-space"
LABEL version="v1.5.5"

ENV VERSION v1.5.5
ENV WEBROOT /var/www/html
ENV SKELETON grav-skeleton-open-publishing-space-site

WORKDIR /var/www 
RUN rm -rf ${WEBROOT}
RUN curl -fSL "https://github.com/hibbitts-design/grav-skeleton-open-publishing-space/releases/download/${VERSION}/${SKELETON}.zip" -o ${SKELETON}.zip 
RUN unzip -q ${SKELETON}.zip
RUN mv ${SKELETON} html 
RUN rm -f ${SKELETON}.zip

WORKDIR ${WEBROOT}
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