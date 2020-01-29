FROM debian:stretch-slim

RUN apt-get -q -y update && \
    apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    jq \
    git \
    unzip

COPY [ "entrypoint.sh", "/entrypoint.sh"] 

RUN chmod +x /entrypoint.sh 

ENTRYPOINT ["/entrypoint.sh"]

