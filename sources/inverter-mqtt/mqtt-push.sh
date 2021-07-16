#!/bin/bash

pushMQTTData () {

    MQTT_SERVER=`cat /etc/inverter/mqtt.json | jq '.server' -r`
    MQTT_PORT=`cat /etc/inverter/mqtt.json | jq '.port' -r`
    MQTT_TOPIC=`cat /etc/inverter/mqtt.json | jq '.topic' -r`
    MQTT_DEVICENAME=`cat /etc/inverter/mqtt.json | jq '.devicename' -r`
    MQTT_USERNAME=`cat /etc/inverter/mqtt.json | jq '.username' -r`
    MQTT_PASSWORD=`cat /etc/inverter/mqtt.json | jq '.password' -r`

    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i ""$MQTT_DEVICENAME"_"$MQTT_SERIAL"" \
        -t "$MQTT_TOPIC/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/$1" \
        -m "$2"
}

INVERTER_DATA=`timeout 10 /opt/inverter-cli/bin/inverter_poller -1`

#####################################################################################

Inverter_mode=`echo $INVERTER_DATA | jq '.Inverter_mode' -r`

 # 1 = Power_On, 2 = Standby, 3 = Line, 4 = Battery, 5 = Fault, 6 = Power_Saving, 7 = Unknown

[ ! -z "$Inverter_mode" ] && pushMQTTData "Inverter_mode" "$Inverter_mode"

AC_grid_voltage=`echo $INVERTER_DATA | jq '.AC_grid_voltage' -r`
[ ! -z "$AC_grid_voltage" ] && pushMQTTData "AC_grid_voltage" "$AC_grid_voltage"

AC_grid_frequency=`echo $INVERTER_DATA | jq '.AC_grid_frequency' -r`
[ ! -z "$AC_grid_frequency" ] && pushMQTTData "AC_grid_frequency" "$AC_grid_frequency"

AC_out_voltage=`echo $INVERTER_DATA | jq '.AC_out_voltage' -r`
[ ! -z "$AC_out_voltage" ] && pushMQTTData "AC_out_voltage" "$AC_out_voltage"

AC_out_frequency=`echo $INVERTER_DATA | jq '.AC_out_frequency' -r`
[ ! -z "$AC_out_frequency" ] && pushMQTTData "AC_out_frequency" "$AC_out_frequency"

PV_in_voltage=`echo $INVERTER_DATA | jq '.PV_in_voltage' -r`
[ ! -z "$PV_in_voltage" ] && pushMQTTData "PV_in_voltage" "$PV_in_voltage"

PV_in_current=`echo $INVERTER_DATA | jq '.PV_in_current' -r`
[ ! -z "$PV_in_current" ] && pushMQTTData "PV_in_current" "$PV_in_current"

PV_in_watts=`echo $INVERTER_DATA | jq '.PV_in_watts' -r`
[ ! -z "$PV_in_watts" ] && pushMQTTData "PV_in_watts" "$PV_in_watts"

PV_in_watthour=`echo $INVERTER_DATA | jq '.PV_in_watthour' -r`
[ ! -z "$PV_in_watthour" ] && pushMQTTData "PV_in_watthour" "$PV_in_watthour"

SCC_voltage=`echo $INVERTER_DATA | jq '.SCC_voltage' -r`
[ ! -z "$SCC_voltage" ] && pushMQTTData "SCC_voltage" "$SCC_voltage"

Load_pct=`echo $INVERTER_DATA | jq '.Load_pct' -r`
[ ! -z "$Load_pct" ] && pushMQTTData "Load_pct" "$Load_pct"

Load_watt=`echo $INVERTER_DATA | jq '.Load_watt' -r`
[ ! -z "$Load_watt" ] && pushMQTTData "Load_watt" "$Load_watt"

Load_watthour=`echo $INVERTER_DATA | jq '.Load_watthour' -r`
[ ! -z "$Load_watthour" ] && pushMQTTData "Load_watthour" "$Load_watthour"

Load_va=`echo $INVERTER_DATA | jq '.Load_va' -r`
[ ! -z "$Load_va" ] && pushMQTTData "Load_va" "$Load_va"

Bus_voltage=`echo $INVERTER_DATA | jq '.Bus_voltage' -r`
[ ! -z "$Bus_voltage" ] && pushMQTTData "Bus_voltage" "$Bus_voltage"

Heatsink_temperature=`echo $INVERTER_DATA | jq '.Heatsink_temperature' -r`
[ ! -z "$Heatsink_temperature" ] && pushMQTTData "Heatsink_temperature" "$Heatsink_temperature"

Battery_capacity=`echo $INVERTER_DATA | jq '.Battery_capacity' -r`
[ ! -z "$Battery_capacity" ] && pushMQTTData "Battery_capacity" "$Battery_capacity"

Battery_voltage=`echo $INVERTER_DATA | jq '.Battery_voltage' -r`
[ ! -z "$Battery_voltage" ] && pushMQTTData "Battery_voltage" "$Battery_voltage"

Battery_charge_current=`echo $INVERTER_DATA | jq '.Battery_charge_current' -r`
[ ! -z "$Battery_charge_current" ] && pushMQTTData "Battery_charge_current" "$Battery_charge_current"

Battery_discharge_current=`echo $INVERTER_DATA | jq '.Battery_discharge_current' -r`
[ ! -z "$Battery_discharge_current" ] && pushMQTTData "Battery_discharge_current" "$Battery_discharge_current"

Load_status_on=`echo $INVERTER_DATA | jq '.Load_status_on' -r`
[ ! -z "$Load_status_on" ] && pushMQTTData "Load_status_on" "$Load_status_on"

SCC_charge_on=`echo $INVERTER_DATA | jq '.SCC_charge_on' -r`
[ ! -z "$SCC_charge_on" ] && pushMQTTData "SCC_charge_on" "$SCC_charge_on"

AC_charge_on=`echo $INVERTER_DATA | jq '.AC_charge_on' -r`
[ ! -z "$AC_charge_on" ] && pushMQTTData "AC_charge_on" "$AC_charge_on"

Battery_recharge_voltage=`echo $INVERTER_DATA | jq '.Battery_recharge_voltage' -r`
[ ! -z "$Battery_recharge_voltage" ] && pushMQTTData "Battery_recharge_voltage" "$Battery_recharge_voltage"

Battery_under_voltage=`echo $INVERTER_DATA | jq '.Battery_under_voltage' -r`
[ ! -z "$Battery_under_voltage" ] && pushMQTTData "Battery_under_voltage" "$Battery_under_voltage"

Battery_bulk_voltage=`echo $INVERTER_DATA | jq '.Battery_bulk_voltage' -r`
[ ! -z "$Battery_bulk_voltage" ] && pushMQTTData "Battery_bulk_voltage" "$Battery_bulk_voltage"

Battery_float_voltage=`echo $INVERTER_DATA | jq '.Battery_float_voltage' -r`
[ ! -z "$Battery_float_voltage" ] && pushMQTTData "Battery_float_voltage" "$Battery_float_voltage"

Max_grid_charge_current=`echo $INVERTER_DATA | jq '.Max_grid_charge_current' -r`
[ ! -z "$Max_grid_charge_current" ] && pushMQTTData "Max_grid_charge_current" "$Max_grid_charge_current"

Max_charge_current=`echo $INVERTER_DATA | jq '.Max_charge_current' -r`
[ ! -z "$Max_charge_current" ] && pushMQTTData "Max_charge_current" "$Max_charge_current"

Out_source_priority=`echo $INVERTER_DATA | jq '.Out_source_priority' -r`
[ ! -z "$Out_source_priority" ] && pushMQTTData "Out_source_priority" "$Out_source_priority"

Charger_source_priority=`echo $INVERTER_DATA | jq '.Charger_source_priority' -r`
[ ! -z "$Charger_source_priority" ] && pushMQTTData "Charger_source_priority" "$Charger_source_priority"

Battery_redischarge_voltage=`echo $INVERTER_DATA | jq '.Battery_redischarge_voltage' -r`
[ ! -z "$Battery_redischarge_voltage" ] && pushMQTTData "Battery_redischarge_voltage" "$Battery_redischarge_voltage"

Warnings=`echo $INVERTER_DATA | jq '.Warnings' -r`
[ ! -z "$Warnings" ] && pushMQTTData "Warnings" "$Warnings"

