FROM quay.io/minio/mc:RELEASE.2021-11-05T10-05-06Z

RUN microdnf update && microdnf install -y tar gzip

COPY run.sh /

RUN chmod +x /run.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
