FROM alpine:3.14.2

RUN apk add --no-cache curl openssl openssl-dev

COPY run.sh /

RUN chmod +x /run.sh

CMD ["/bin/bash", "/run.sh"]
