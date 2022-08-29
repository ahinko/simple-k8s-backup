FROM quay.io/minio/mc:RELEASE.2022-08-28T20-08-11Z

RUN microdnf update && microdnf install -y tar gzip && microdnf reinstall -y tzdata

COPY run.sh sleep.sh /

RUN chmod +x /run.sh /sleep.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
