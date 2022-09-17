FROM quay.io/minio/mc:RELEASE.2022-09-16T09-16-47Z

RUN microdnf update && microdnf install -y tar gzip && microdnf reinstall -y tzdata

COPY run.sh sleep.sh /

RUN chmod +x /run.sh /sleep.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
