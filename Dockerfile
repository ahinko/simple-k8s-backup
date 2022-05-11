FROM quay.io/minio/mc:RELEASE.2022-05-09T04-08-26Z

RUN microdnf update && microdnf install -y tar gzip && microdnf reinstall -y tzdata

COPY run.sh /

RUN chmod +x /run.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
