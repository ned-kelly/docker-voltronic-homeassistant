FROM debian:stretch

RUN apt update && apt install -y \
        curl \
        git \
        build-essential \
        cmake \
        jq \
        mosquitto-clients

ADD sources/ /opt/
ADD config/ /etc/skymax/

RUN cd /opt/voltronic-cli && \
    mkdir bin && cmake . && make

WORKDIR /opt
ENTRYPOINT ["/bin/bash", "/opt/voltronic-mqtt/entrypoint.sh"]