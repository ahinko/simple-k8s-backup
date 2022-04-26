FROM quay.io/minio/mc:RELEASE.2022-04-16T21-11-21Z

RUN microdnf update && microdnf install -y tar gzip tzdata

COPY run.sh /

RUN chmod +x /run.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
