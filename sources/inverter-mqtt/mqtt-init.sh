##!/bin/bash
#
# Simple script to register the MQTT topics when the container starts for the first time...

MQTT_SERVER=`cat /etc/inverter/mqtt.json | jq '.server' -r`
MQTT_PORT=`cat /etc/inverter/mqtt.json | jq '.port' -r`
MQTT_TOPIC=`cat /etc/inverter/mqtt.json | jq '.topic' -r`
MQTT_DEVICENAME=`cat /etc/inverter/mqtt.json | jq '.devicename' -r`
MQTT_MANUFACTURER=`cat /etc/inverter/mqtt.json | jq '.manufacturer' -r`
MQTT_MODEL=`cat /etc/inverter/mqtt.json | jq '.model' -r`
MQTT_SERIAL=`cat /etc/inverter/mqtt.json | jq '.serial' -r`
MQTT_VER=`cat /etc/inverter/mqtt.json | jq '.ver' -r`
MQTT_USERNAME=`cat /etc/inverter/mqtt.json | jq '.username' -r`
MQTT_PASSWORD=`cat /etc/inverter/mqtt.json | jq '.password' -r`

registerTopic () {
    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i ""$MQTT_DEVICENAME"_"$MQTT_SERIAL"" \
        -t ""$MQTT_TOPIC"/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/$1/config" \
        -r \
        -m "{
            \"name\": \"$1_"$MQTT_DEVICENAME"\",
            \"uniq_id\": \""$MQTT_SERIAL"_$1\",
            \"device\": { \"ids\": \""$MQTT_SERIAL"\", \"mf\": \""$MQTT_MANUFACTURER"\", \"mdl\": \""$MQTT_MODEL"\", \"name\": \""$MQTT_DEVICENAME"\", \"sw\": \""$MQTT_VER"\"},
            \"state_topic\": \""$MQTT_TOPIC"/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/$1\",
            \"state_class\": \"measurement\",
            \"unit_of_meas\": \"$2\",
            \"icon\": \"mdi:$3\"
        }"
}
registerEnergyTopic () {
    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i ""$MQTT_DEVICENAME"_"$MQTT_SERIAL"" \
        -t "$MQTT_TOPIC/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/$1/LastReset" \
		-r \
        -m "1970-01-01T00:00:00+00:00"

    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i ""$MQTT_DEVICENAME"_"$MQTT_SERIAL"" \
        -t ""$MQTT_TOPIC"/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/$1/config" \
        -r \
        -m "{
            \"name\": \"$1_"$MQTT_DEVICENAME"\",
            \"uniq_id\": \""$MQTT_SERIAL"_$1\",
            \"device\": { \"ids\": \""$MQTT_SERIAL"\", \"mf\": \""$MQTT_MANUFACTURER"\", \"mdl\": \""$MQTT_MODEL"\", \"name\": \""$MQTT_DEVICENAME"\", \"sw\": \""$MQTT_VER"\"},
            \"state_topic\": \""$MQTT_TOPIC"/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/$1\",
            \"last_reset_topic\": \""$MQTT_TOPIC"/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/$1/LastReset\",			
            \"state_class\": \"measurement\",
            \"device_class\": \"$4\",
            \"unit_of_meas\": \"$2\",
            \"icon\": \"mdi:$3\"
        }"
}
registerInverterRawCMD () {
    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i ""$MQTT_DEVICENAME"_"$MQTT_SERIAL"" \
        -t ""$MQTT_TOPIC"/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/COMMANDS/config" \
        -r \
        -m "{
            \"name\": \""$MQTT_DEVICENAME"_COMMANDS\",
            \"uniq_id\": \""$MQTT_DEVICENAME"_"$MQTT_SERIAL"\",
            \"device\": { \"ids\": \""$MQTT_SERIAL"\", \"mf\": \""$MQTT_MANUFACTURER"\", \"mdl\": \""$MQTT_MODEL"\", \"name\": \""$MQTT_DEVICENAME"\", \"sw\": \""$MQTT_VER"\"},
            \"state_topic\": \""$MQTT_TOPIC"/sensor/"$MQTT_DEVICENAME"_"$MQTT_SERIAL"/COMMANDS\"
            }"
}

registerTopic "AC_charge_on" "" "power" "none"
registerTopic "AC_grid_frequency" "Hz" "current-ac" "none"
registerTopic "AC_grid_voltage" "V" "power-plug" "voltage"
registerTopic "AC_out_frequency" "Hz" "current-ac" "none"
registerTopic "AC_out_voltage" "V" "power-plug" "voltage"
registerTopic "Battery_bulk_voltage" "V" "current-dc" "voltage"
registerTopic "Battery_capacity" "%" "battery-outline" "battery"
registerTopic "Battery_charge_current" "A" "current-dc" "current"
registerTopic "Battery_discharge_current" "A" "current-dc" "current"
registerTopic "Battery_float_voltage" "V" "current-dc" "voltage"
registerTopic "Battery_recharge_voltage" "V" "current-dc" "voltage"
registerTopic "Battery_redischarge_voltage" "V" "battery-negative" "voltage"
registerTopic "Battery_under_voltage" "V" "current-dc" "voltage"
registerTopic "Battery_voltage" "V" "battery-outline" "voltage"
registerTopic "Bus_voltage" "V" "details" "voltage"
registerTopic "Charger_source_priority" "" "solar-power" "none"
registerTopic "Heatsink_temperature" "°C" "details" "temperature"
registerTopic "Load_pct" "%" "brightness-percent" "none"
registerTopic "Load_status_on" "" "power" "none"
registerTopic "Load_va" "VA" "chart-bell-curve" "current"
registerTopic "Load_watt" "W" "chart-bell-curve" "power"
registerEnergyTopic "Load_watthour" "Wh" "chart-bell-curve" "energy"
registerTopic "Max_charge_current" "A" "current-ac" "current"
registerTopic "Max_grid_charge_current" "A" "current-ac" "current"
registerTopic "Mode" "" "solar-power" "" # 1 = Power_On, 2 = Standby, 3 = Line, 4 = Battery, 5 = Fault, 6 = Power_Saving, 7 = Unknown
registerTopic "Out_source_priority" "" "grid" "none"
registerTopic "PV_in_current" "A" "solar-panel-large" "current"
registerTopic "PV_in_voltage" "V" "solar-panel-large" "voltage"
registerEnergyTopic "PV_in_watthour" "Wh" "solar-panel-large" "energy"
registerTopic "PV_in_watts" "W" "solar-panel-large" "power"
registerTopic "SCC_charge_on" "" "power" "none"
registerTopic "SCC_voltage" "V" "current-dc" "none"

# Add in a separate topic so we can send raw commands from assistant back to the inverter via MQTT (such as changing power modes etc)...
registerInverterRawCMD
