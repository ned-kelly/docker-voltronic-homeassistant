#!/bin/bash

MQTT_SERVER=`cat /etc/skymax/mqtt.json | jq '.server' -r`
MQTT_PORT=`cat /etc/skymax/mqtt.json | jq '.port' -r`
MQTT_TOPIC=`cat /etc/skymax/mqtt.json | jq '.topic' -r`
MQTT_DEVICENAME=`cat /etc/skymax/mqtt.json | jq '.devicename' -r`

while read rawcmd;
do

    echo "Incoming request send: [$rawcmd] to inverter."
    /opt/voltronic-cli/bin/skymax -r $rawcmd;

done < <(mosquitto_sub -h $MQTT_SERVER -p $MQTT_PORT -t "$MQTT_TOPIC/sensor/$MQTT_DEVICENAME" -q 1)
