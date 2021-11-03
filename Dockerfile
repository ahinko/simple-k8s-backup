FROM quay.io/minio/mc:RELEASE.2021-10-07T04-19-58Z

RUN microdnf update && microdnf install -y tar

COPY run.sh /

RUN chmod +x /run.sh

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

CMD [ "/run.sh" ]
