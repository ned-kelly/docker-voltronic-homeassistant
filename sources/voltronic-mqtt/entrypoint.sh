#!/bin/bash
export TERM=xterm

# Init the mqtt server for the first time...
bash /opt/voltronic-mqtt/mqtt-init.sh

# Run the MQTT Subscriber process in the background (so that way we can change the configuration on the inverter from home assistant)
/opt/voltronic-mqtt/mqtt-subscriber.sh &

# execute exactly ever minute...
watch -n 30 /opt/voltronic-mqtt/mqtt-push.sh # > /dev/null 2>&1
