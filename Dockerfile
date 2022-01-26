FROM node:17-alpine3.14 AS Builder
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
WORKDIR /app
ENV VER 1.5.7
RUN apk add curl
RUN curl -L https://github.com/doocs/md/archive/refs/tags/v${VER}.zip -o v${VER}.zip && unzip v${VER}.zip && mv md-${VER}/* /app/
COPY patch/vue.config.js /app/vue.config.js
COPY patch/mm.config.js /app/mm/mm.config.js
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm i -g cnpm --registry=https://registry.npmmirror.com && cnpm i && npm run build


FROM golang:1.17.6-alpine3.15 AS GoBuilder
COPY --from=Builder /app/dist /app/assets
COPY main.go /app
RUN apk add git bash gcc musl-dev upx
WORKDIR /app
RUN go build -ldflags "-w -s" -o md main.go && \
    apk add upx && \
    upx -9 -o md.minify md


FROM alpine:3.15
LABEL MAINTAINER soulteary<soulteary@gmail.com>
COPY --from=GoBuilder /app/md.minify /bin/md
CMD ["md"]
