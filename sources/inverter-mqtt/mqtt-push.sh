#!/bin/bash
INFLUX_ENABLED=`cat /etc/inverter/mqtt.json | jq '.influx.enabled' -r`

MQTT_SERVER=`cat /etc/inverter/mqtt.json | jq '.server' -r`
MQTT_PORT=`cat /etc/inverter/mqtt.json | jq '.port' -r`
MQTT_TOPIC=`cat /etc/inverter/mqtt.json | jq '.topic' -r`
MQTT_DEVICENAME=`cat /etc/inverter/mqtt.json | jq '.devicename' -r`
MQTT_USERNAME=`cat /etc/inverter/mqtt.json | jq '.username' -r`
MQTT_PASSWORD=`cat /etc/inverter/mqtt.json | jq '.password' -r`
MQTT_CLIENTID=`cat /etc/inverter/mqtt.json | jq '.clientid' -r`

pushMQTTData () {
    param=$1
    value=`echo $INVERTER_DATA| sed --expression "sK.*\"$param\":\([^,}]*\).*K\1K"`

    if test -z $value; then
	return
    fi

    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i $MQTT_CLIENTID \
        -t "$MQTT_TOPIC/sensor/"$MQTT_DEVICENAME"_$param" \
        -m "$value"
    
    if [[ $INFLUX_ENABLED == "true" ]] ; then
        pushInfluxData $param $value
    fi
}

pushInfluxData () {
    INFLUX_HOST=`cat /etc/inverter/mqtt.json | jq '.influx.host' -r`
    INFLUX_USERNAME=`cat /etc/inverter/mqtt.json | jq '.influx.username' -r`
    INFLUX_PASSWORD=`cat /etc/inverter/mqtt.json | jq '.influx.password' -r`
    INFLUX_DEVICE=`cat /etc/inverter/mqtt.json | jq '.influx.device' -r`
    INFLUX_PREFIX=`cat /etc/inverter/mqtt.json | jq '.influx.prefix' -r`
    INFLUX_DATABASE=`cat /etc/inverter/mqtt.json | jq '.influx.database' -r`
    INFLUX_MEASUREMENT_NAME=`cat /etc/inverter/mqtt.json | jq '.influx.namingMap.'$1'' -r`
    
    curl -i -XPOST "$INFLUX_HOST/write?db=$INFLUX_DATABASE&precision=s" -u "$INFLUX_USERNAME:$INFLUX_PASSWORD" --data-binary "$INFLUX_PREFIX,device=$INFLUX_DEVICE $INFLUX_MEASUREMENT_NAME=$2"
}

INVERTER_DATA=`timeout 10 /opt/inverter-cli/bin/inverter_poller -1`

#####################################################################################
# Inverter_Mode: 1 = Power_On, 2 = Standby, 3 = Line, 4 = Battery, 5 = Fault, 6 = Power_Saving, 7 = Unknown

for w in Inverter_mode AC_grid_voltage AC_grid_frequency AC_out_voltage AC_out_frequency PV_in_voltage PV_in_current PV_in_watts PV_in_watthour SCC_voltage Load_pct Load_watt Load_watthour Load_va Bus_voltage Heatsink_temperature Battery_capacity Battery_voltage Battery_charge_current Battery_discharge_current Load_status_on SCC_charge_on AC_charge_on Battery_recharge_voltage Battery_under_voltage Battery_bulk_voltage Battery_float_voltage Max_grid_charge_current Max_charge_current Out_source_priority Charger_source_priority Battery_redischarge_voltage Warnings; do
    pushMQTTData $w
done
