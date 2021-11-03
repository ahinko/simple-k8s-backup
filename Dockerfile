FROM quay.io/minio/mc:RELEASE.2021-09-23T05-44-03Z

COPY run.sh /

RUN chmod +x /run.sh

CMD ["/bin/bash", "/run.sh"]
