#!/bin/bash

UNBUFFER='stdbuf -i0 -oL -eL'

# stty -F /dev/ttyUSB0 2400 raw

# Init the mqtt server.  This creates the config topics in the MQTT server
# that the MQTT integration uses to create entities in HA.

# broker using persistence (default HA config)
$UNBUFFER /opt/inverter-mqtt/mqtt-init.sh

# broker not using persistence
#(while :; do $UNBUFFER /opt/inverter-mqtt/mqtt-init.sh; sleep 300; done) &

# Run the MQTT subscriber process in the background (so that way we can change
# the configuration on the inverter from home assistant).
$UNBUFFER /opt/inverter-mqtt/mqtt-subscriber.sh &

# Push poller updates every 30 seconds.
while :; do $UNBUFFER /opt/inverter-mqtt/mqtt-push.sh; sleep 30; done
