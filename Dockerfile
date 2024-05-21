FROM node:alpine

LABEL org.opencontainers.image.title="md-check-links"
LABEL org.opencontainers.image.description="Checks that links in markdown are working"
LABEL org.opencontainers.image.documentation="https://github.com/YakDriver/md-check-links/blob/main/README.md"
LABEL org.opencontainers.image.source="https://github.com/YakDriver/md-check-links"

RUN apk add --no-cache bash>5.0.16-r0 git>2.44 nodejs>21.6 npm>10
RUN set -ex; \
    npm install
RUN npm i -g yarn@1.22.22 --force
RUN npm i -g markdown-link-check@3.11.2
COPY package*.json ./
COPY . .
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
