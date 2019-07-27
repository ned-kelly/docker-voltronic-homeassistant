#!/bin/bash

MQTT_SERVER=`cat /etc/inverter/mqtt.json | jq '.server' -r`
MQTT_PORT=`cat /etc/inverter/mqtt.json | jq '.port' -r`
MQTT_TOPIC=`cat /etc/inverter/mqtt.json | jq '.topic' -r`
MQTT_DEVICENAME=`cat /etc/inverter/mqtt.json | jq '.devicename' -r`

while read rawcmd;
do

    echo "Incoming request send: [$rawcmd] to inverter."
    /opt/inverter-cli/bin/inverter_poller -r $rawcmd;

done < <(mosquitto_sub -h $MQTT_SERVER -p $MQTT_PORT -t "$MQTT_TOPIC/sensor/$MQTT_DEVICENAME" -q 1)
