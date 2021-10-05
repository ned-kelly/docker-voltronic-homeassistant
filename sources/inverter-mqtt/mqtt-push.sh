#!/bin/bash

MQTT_SERVER=`cat /etc/inverter/mqtt.json | jq '.server' -r`
MQTT_PORT=`cat /etc/inverter/mqtt.json | jq '.port' -r`
MQTT_TOPIC=`cat /etc/inverter/mqtt.json | jq '.topic' -r`
MQTT_DEVICENAME=`cat /etc/inverter/mqtt.json | jq '.devicename' -r`
MQTT_USERNAME=`cat /etc/inverter/mqtt.json | jq '.username' -r`
MQTT_PASSWORD=`cat /etc/inverter/mqtt.json | jq '.password' -r`

INFLUX_ENABLED=`cat /etc/inverter/mqtt.json | jq '.influx.enabled' -r`
if [[ $INFLUX_ENABLED == "true" ]] ; then
    INFLUX_HOST=`cat /etc/inverter/mqtt.json | jq '.influx.host' -r`
    INFLUX_USERNAME=`cat /etc/inverter/mqtt.json | jq '.influx.username' -r`
    INFLUX_PASSWORD=`cat /etc/inverter/mqtt.json | jq '.influx.password' -r`
    INFLUX_DEVICE=`cat /etc/inverter/mqtt.json | jq '.influx.device' -r`
    INFLUX_PREFIX=`cat /etc/inverter/mqtt.json | jq '.influx.prefix' -r`
    INFLUX_DATABASE=`cat /etc/inverter/mqtt.json | jq '.influx.database' -r`
    INFLUX_MEASUREMENT_NAME=`cat /etc/inverter/mqtt.json | jq '.influx.namingMap.'$1'' -r`
fi

pushMQTTData () {
    if [ -n "$2" ]; then
        mosquitto_pub \
            -h $MQTT_SERVER \
            -p $MQTT_PORT \
            -u "$MQTT_USERNAME" \
            -P "$MQTT_PASSWORD" \
	    -r \
            -t "$MQTT_TOPIC/sensor/"$MQTT_DEVICENAME"_$1" \
            -m "$2"
    
        if [[ $INFLUX_ENABLED == "true" ]] ; then
            pushInfluxData "$1" "$2"
        fi
    fi
}

pushInfluxData () {
    curl -i -XPOST "$INFLUX_HOST/write?db=$INFLUX_DATABASE&precision=s" -u "$INFLUX_USERNAME:$INFLUX_PASSWORD" --data-binary "$INFLUX_PREFIX,device=$INFLUX_DEVICE $INFLUX_MEASUREMENT_NAME=$2"
}

###############################################################################

# Inverter modes: 1 = Power_On, 2 = Standby, 3 = Line, 4 = Battery, 5 = Fault, 6 = Power_Saving, 7 = Unknown

POLLER_JSON=$(timeout 10 /opt/inverter-cli/bin/inverter_poller -1)
BASH_HASH=$(echo $POLLER_JSON | jq -r '. | to_entries | .[] | @sh "[\(.key)]=\(.value)"')
eval "declare -A INVERTER_DATA=($BASH_HASH)"

for key in "${!INVERTER_DATA[@]}"; do
    pushMQTTData "$key" "${INVERTER_DATA[$key]}"
done

