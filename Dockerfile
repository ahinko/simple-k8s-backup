FROM quay.io/minio/mc:RELEASE.2023-05-04T18-10-16Z AS mc
FROM public.ecr.aws/docker/library/alpine:3.18.0

COPY --from=mc /usr/bin/mc /usr/bin/mc

RUN apk update && \
  apk add --no-cache ca-certificates tar bash curl gzip tzdata

COPY run.sh sleep.sh /

RUN chmod +x /run.sh /sleep.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
