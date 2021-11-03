FROM quay.io/minio/mc:RELEASE.2021-10-07T04-19-58Z

COPY run.sh /

RUN chmod +x /run.sh

CMD ["/bin/bash", "/run.sh"]
