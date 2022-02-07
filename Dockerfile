FROM quay.io/minio/mc:RELEASE.2022-02-07T09-25-34Z

RUN microdnf update && microdnf install -y tar gzip

COPY run.sh /

RUN chmod +x /run.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
