FROM node:lts-alpine
RUN apk add --no-cache bash>5.0.16-r0 git>2.35.0-r0 nodejs>16.14 npm>8
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
