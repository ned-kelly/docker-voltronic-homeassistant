#!/bin/bash
#
# Simple script to register the MQTT topics when the container starts for the first time...

MQTT_SERVER=`cat /etc/skymax/mqtt.json | jq '.server' -r`
MQTT_PORT=`cat /etc/skymax/mqtt.json | jq '.port' -r`
MQTT_TOPIC=`cat /etc/skymax/mqtt.json | jq '.topic' -r`
MQTT_DEVICENAME=`cat /etc/skymax/mqtt.json | jq '.devicename' -r`

registerTopic () {
    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -t "$MQTT_TOPIC/sensor/"$MQTT_DEVICENAME"_$1/config" \
        -m "{
            \"name\": \""$MQTT_DEVICENAME"_$1\",
            \"unit_of_measurement\": \"$2\",
            \"state_topic\": \"$MQTT_TOPIC/sensor/"$MQTT_DEVICENAME"_$1\",
            \"icon\": \"mdi:$3\"
        }"
}

registerInverterRawCMD () {
    mosquitto_pub \
        -h $MQTT_SERVER \
        -p $MQTT_PORT \
        -t "$MQTT_TOPIC/sensor/$MQTT_DEVICENAME/config" \
        -m "{
            \"name\": \""$MQTT_DEVICENAME"\",
            \"state_topic\": \"$MQTT_TOPIC/sensor/$MQTT_DEVICENAME\"
        }"
}

registerTopic "Inverter_mode" "" "mdi-solar-power" # 1 = Power_On, 2 = Standby, 3 = Line, 4 = Battery, 5 = Fault, 6 = Power_Saving, 7 = Unknown
registerTopic "AC_grid_voltage" "V" "mdi-power-plug"
registerTopic "AC_grid_frequency" "Hz" "mdi-current-ac"
registerTopic "AC_out_voltage" "V" "mdi-power-plug"
registerTopic "AC_out_frequency" "Hz" "mdi-current-ac"
registerTopic "PV_in_voltage" "V" "mdi-solar-panel-large"
registerTopic "PV_in_current" "A" "mdi-solar-panel-large"
registerTopic "PV_in_watts" "W" "mdi-solar-panel-large"
registerTopic "PV_in_watthour" "Wh" "mdi-solar-panel-large"
registerTopic "SCC_voltage" "V" "mdi-current-dc"
registerTopic "Load_pct" "%" "mdi-brightness-percent"
registerTopic "Load_watt" "W" "mdi-chart-bell-curve"
registerTopic "Load_watthour" "Wh" "mdi-chart-bell-curve"
registerTopic "Load_va" "VA" "mdi-chart-bell-curve"
registerTopic "Bus_voltage" "V" "mdi-details"
registerTopic "Heatsink_temperature" "" "mdi-details"
registerTopic "Battery_capacity" "%" "mdi-battery-outline"
registerTopic "Battery_voltage" "V" "mdi-battery-outline"
registerTopic "Battery_charge_current" "A" "mdi-current-dc"
registerTopic "Battery_discharge_current" "A" "mdi-current-dc"
registerTopic "Load_status_on" "" "mdi-power"
registerTopic "SCC_charge_on" "" "mdi-power"
registerTopic "AC_charge_on" "" "mdi-power"
registerTopic "Battery_recharge_voltage" "V" "mdi-current-dc"
registerTopic "Battery_under_voltage" "V" "mdi-current-dc"
registerTopic "Battery_bulk_voltage" "V" "mdi-current-dc"
registerTopic "Battery_float_voltage" "V" "mdi-current-dc"
registerTopic "Max_grid_charge_current" "A" "mdi-current-ac"
registerTopic "Max_charge_current" "A" "mdi-current-ac"
registerTopic "Out_source_priority" "" "mdi-grid"
registerTopic "Charger_source_priority" "" "mdi-solar-power"
registerTopic "Battery_redischarge_voltage" "V" "mdi-battery-negative"

# Add in a separate topic so we can send raw commands from assistant back to the inverter via MQTT (such as changing power modes etc)...
registerInverterRawCMD
