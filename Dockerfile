FROM quay.io/minio/mc:RELEASE.2023-01-28T20-29-38Z AS mc
FROM alpine:3.17.2

COPY --from=mc /usr/bin/mc /usr/bin/mc

RUN apk update && \
  apk add --no-cache ca-certificates tar bash curl gzip tzdata

COPY run.sh sleep.sh /

RUN chmod +x /run.sh /sleep.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
