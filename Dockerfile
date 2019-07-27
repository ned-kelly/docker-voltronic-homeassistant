FROM debian:stretch

RUN apt update && apt install -y \
        curl \
        git \
        build-essential \
        cmake \
        jq \
        mosquitto-clients

ADD sources/ /opt/
ADD config/ /etc/inverter/

RUN cd /opt/inverter-cli && \
    mkdir bin && cmake . && make && mv inverter_poller bin/

WORKDIR /opt
ENTRYPOINT ["/bin/bash", "/opt/inverter-mqtt/entrypoint.sh"]