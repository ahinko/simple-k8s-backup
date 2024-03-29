FROM quay.io/minio/mc:RELEASE.2024-02-09T22-18-24Z AS mc
FROM public.ecr.aws/docker/library/alpine:3.19.1

COPY --from=mc /usr/bin/mc /usr/bin/mc

RUN apk update && \
  apk add --no-cache ca-certificates tar bash curl gzip tzdata

COPY run.sh sleep.sh /

RUN chmod +x /run.sh /sleep.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
