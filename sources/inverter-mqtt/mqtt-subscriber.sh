#!/bin/bash

MQTT_SERVER=`cat /etc/inverter/mqtt.json | jq '.server' -r`
MQTT_PORT=`cat /etc/inverter/mqtt.json | jq '.port' -r`
MQTT_TOPIC=`cat /etc/inverter/mqtt.json | jq '.topic' -r`
MQTT_DEVICENAME=`cat /etc/inverter/mqtt.json | jq '.devicename' -r`
MQTT_USERNAME=`cat /etc/inverter/mqtt.json | jq '.username' -r`
MQTT_PASSWORD=`cat /etc/inverter/mqtt.json | jq '.password' -r`

function subscribe () {
    mosquitto_sub -h $MQTT_SERVER -p $MQTT_PORT -u "$MQTT_USERNAME" -P "$MQTT_PASSWORD" -t "$MQTT_TOPIC/sensor/$MQTT_DEVICENAME" -q 1
}

function reply () {
    mosquitto_pub -h $MQTT_SERVER -p $MQTT_PORT -u "$MQTT_USERNAME" -P "$MQTT_PASSWORD" -t "$MQTT_TOPIC/sensor/${MQTT_DEVICENAME}/reply" -q 1 -m "$*"
}

subscribe | while read rawcmd; do
    echo "[$(date +%F+%T)] Incoming request send: [$rawcmd] to inverter."
    for attempt in $(seq 3); do
	REPLY=$(/opt/inverter-cli/bin/inverter_poller -r $rawcmd)
	echo "[$(date +%F+%T)] $REPLY"
        reply "[$rawcmd] [Attempt $attempt] [$REPLY]"
	[ "$REPLY" = "Reply:  ACK" ] && break
	[ "$attempt" != "3" ] && sleep 1
    done
done
