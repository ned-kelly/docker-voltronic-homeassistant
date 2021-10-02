#!/bin/bash
export TERM=xterm

# stty -F /dev/ttyUSB0 2400 raw

# Init the mqtt server for the first time, then every 5 minutes
# This will re-create the auto-created topics in the MQTT server if HA is restarted...

watch -xn 300 /opt/inverter-mqtt/mqtt-init.sh &

# Run the MQTT Subscriber process in the background (so that way we can change the configuration on the inverter from home assistant)
# This normally doesn't exit, but the watch is needed to handle mqtt server restarts.
watch -xn 1 /opt/inverter-mqtt/mqtt-subscriber.sh &

# execute exactly every 30 seconds...
watch -xn 30 /opt/inverter-mqtt/mqtt-push.sh
