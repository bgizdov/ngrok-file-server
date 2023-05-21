############### indexserver build stage ###############

FROM node:18-alpine AS builder
WORKDIR /app

# install all dependencies for build
COPY indexserver/package.json indexserver/yarn.lock ./
RUN yarn install

# build
COPY indexserver/ ./
RUN yarn build

# install just the production dependencies
RUN rm -rf ./node_modules
RUN yarn install --production 
RUN mv node_modules .dist/node_modules


FROM ngrok/ngrok:alpine AS ngrok

############### main stage ###############

FROM nginx:1.24-alpine-slim AS main

# install s6-overlay
# ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/s6-overlay-installer
COPY --from=peterberweiler/s6-overlay-installer:latest /installer /tmp/s6-overlay-installer
RUN chmod +x /tmp/s6-overlay-installer && /tmp/s6-overlay-installer /

# install nodejs 14
RUN apk update && apk add nodejs

# move nginx docker-entrypoint to initialization tasks
RUN mv /docker-entrypoint.sh /etc/cont-init.d/nginx-setup.sh

# copy nginx config
COPY ./nginx-default.conf /etc/nginx/conf.d/default.conf

# copy init-scripts to initialization tasks
COPY ./init-scripts/* /etc/cont-init.d/

# add indexserver service
COPY ./run-scripts/indexserver.sh /etc/services.d/indexserver/run

# copy indexserver build
COPY --from=builder /app/.dist/ /app/

# s6-overlay settings
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_CMD_WAIT_FOR_SERVICES=1
ENV S6_KEEP_ENV=1

############### ngrok setup ###############
COPY --from=ngrok /bin/ngrok /usr/local/bin/ngrok
COPY --from=ngrok /var/lib/ngrok /var/lib/ngrok

ENTRYPOINT ["/init"]
CMD ["nginx", "-g", "daemon off;"]
