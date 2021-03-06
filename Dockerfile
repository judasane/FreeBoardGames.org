FROM node:13.12.0-buster                                                                       

# do not run as root
RUN groupadd -g 999 appuser && useradd -m -d /appdata -r -u 999 -g appuser appuser
RUN rm /bin/su
USER appuser
RUN mkdir -p /appdata/blog

# add node_modules to PATH
ENV PATH /appdata/node_modules/.bin:$PATH

# blog
COPY --chown=appuser blog/yarn.lock /appdata/blog
COPY --chown=appuser blog/package.json /appdata/blog
WORKDIR /appdata/blog/
RUN yarn install
# build blog:
COPY --chown=appuser blog /appdata/blog
RUN yarn run hexo generate

# install and cache app dependencies
COPY --chown=appuser tsconfig.json package.json yarn.lock /appdata/
#COPY --chown=appuser local_registry /appdata/local_registry
WORKDIR /appdata
RUN yarn install

# config
COPY --chown=appuser tsconfig.server.json webpack.server.config.js /appdata/

# build server
COPY --chown=appuser src /appdata/src
COPY --chown=appuser server /appdata/server
RUN yarn run build:server

# build website
ARG GA_TRACKING_CODE
ARG GTM_ID
ARG BGIO_SERVER_URL
ARG GIT_REV
COPY --chown=appuser .babelrc next.config.js /appdata/
COPY --chown=appuser static /appdata/static
RUN yarn run build

WORKDIR /appdata
COPY --chown=appuser docker_run.sh /appdata/
CMD ./docker_run.sh
