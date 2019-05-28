## A Docker based Home Assistant interface for Voltronic Solar Inverters 

This project [was derived](https://github.com/leithhobson/skymax-demo-Original) from the 'skymax' [C based monitoring application](https://skyboo.net/2017/03/monitoring-voltronic-power-axpert-mex-inverter-under-linux/) designed to take the monitoring data from Voltronic, Axpert, Mppsolar PIP, Voltacon, Effekta, and other branded OEM Inverters and send it to a Home Assistant MQTT server for ingestion...

The program can also receive commands from Home Assistant (via MQTT) to change the state of the inverter remotely.

By remotely setting values via MQTT you can for example, change the power mode to '_solar only_' during the day, but then change back to '_grid mode charging_' for your AGM batteries in the evenings - But if it's raining (based on data from your weather station), Set the charge mode to `PCP02` _(Charge based on 'Solar and Utility')_...

The program is designed to be run in a Docker Container, and can be deployed on a lightweight SBC next to your Inverter (i.e. an Orange Pi Zero running Arabian), and read data via the RS232 or USB ports on the back of the Inverter.

----


