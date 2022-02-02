FROM quay.io/minio/mc:RELEASE.2022-02-02T02-03-24Z

RUN microdnf update && microdnf install -y tar gzip

COPY run.sh /

RUN chmod +x /run.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
