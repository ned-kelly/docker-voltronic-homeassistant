# A Docker based Home Assistant interface for Voltronic Solar Inverters 

This project [was derived](https://github.com/leithhobson/skymax-demo-Original) from the 'skymax' [C based monitoring application](https://skyboo.net/2017/03/monitoring-voltronic-power-axpert-mex-inverter-under-linux/) designed to take the monitoring data from Voltronic, Axpert, Mppsolar PIP, Voltacon, Effekta, and other branded OEM Inverters and send it to a Home Assistant MQTT server for ingestion...

The program can also receive commands from Home Assistant (via MQTT) to change the state of the inverter remotely.

By remotely setting values via MQTT you can for example, change the power mode to '_solar only_' during the day, but then change back to '_grid mode charging_' for your AGM batteries in the evenings - But if it's raining (based on data from your weather station), Set the charge mode to `PCP02` _(Charge based on 'Solar and Utility')_...

The program is designed to be run in a Docker Container, and can be deployed on a lightweight SBC next to your Inverter (i.e. an Orange Pi Zero running Arabian), and read data via the RS232 or USB ports on the back of the Inverter.

![Example Lovelace Dashboard](images/lovelace-dashboard.jpg "Example Lovelace Dashboard")
_Example: My "Lovelace" dashboard using data collected from the Inverter._

----

**Docker Hub:** [`bushrangers/ha-voltronic-mqtt`](https://hub.docker.com/r/bushrangers/ha-voltronic-mqtt/)

![License](https://img.shields.io/github/license/ned-kelly/docker-voltronic-homeassistant.svg) ![Docker Pulls](https://img.shields.io/docker/pulls/bushrangers/ha-voltronic-mqtt.png)

## Prerequisites

- Docker
- Docker-compose
- [Voltronic](https://www.ebay.com.au/sch/i.html?_from=R40&_trksid=p2334524.m570.l1313.TR11.TRC1.A0.H0.Xaxpert+inverter.TRS0&_nkw=axpert+inverter&_sacat=0&LH_TitleDesc=0&LH_PrefLoc=2&_osacat=0&_odkw=solar+inverter&LH_TitleDesc=0) based inverter that you want to monitor
- Home Assistant [running with a MQTT Server](https://www.home-assistant.io/components/mqtt/)


## Configuration & Standing Up

It's pretty straightforward, just clone down the sources and set the configuration files in the `config/` directory:

```bash
# Clone down sources on the host you want to monitor...
git clone https://github.com/ned-kelly/docker-voltronic-homeassistant.git /opt/ha-voltronic-mqtt
cd /opt/ha-voltronic-mqtt

# Configure the 'device=' directive (in skymax.conf) to suit for RS232 or USB.. 
vi config/skymax.conf

# Configure your MQTT server host, port, Home Assistant topic, and name of the Inverter that you want displayed in Home Assistant.
vi config/mqtt.json
```

Then, plug in your Serial or USB cable to the Inverter & stand up the container:

```bash
docker-compose up -d

```

_Note if you have issues standing up the image on your Linux distribution, you may need to manually build the image - This can be done by uncommenting the build flag in your docker-compose.yml file._

## Integrating into Home Assistant.

Providing you have setup [MQTT](https://www.home-assistant.io/components/mqtt/) with Home Assistant, the device will automatically register in your Home Assistant when the container starts for the first time -- You do not need to manually define any sensors.

From here you can setup [Graphs](https://www.home-assistant.io/lovelace/history-graph/) to display sensor data, and optionally change state of the inverter by "[publishing](https://www.home-assistant.io/docs/mqtt/service/)" a string to the inverter's primary topic like so:

![Example, Changing the Charge Priority](images/mqtt-publish-packet.png "Example, Changing the Charge Priority")
_Example: Changing the Charge Priority of the Inverter_

**COMMON COMMANDS THAT CAN BE SENT TO THE INVERTER**

_(see [protocol manual](http://forums.aeva.asn.au/uploads/293/HS_MS_MSX_RS232_Protocol_20140822_after_current_upgrade.pdf) for complete list of supported commands)_



```
DESCRIPTION:                PAYLOAD:  OPTIONS:
----------------------------------------------------------------
Set output source priority  POP00     (Utility first)
                            POP01     (Solar first)
                            POP02     (SBU)

Set charger priority        PCP00     (Utility first)
                            PCP01     (Solar first)
                            PCP02     (Solar and utility)
                            PCP03     (Solar only)

Set the Charge/Discharge Levels
                            PBDV25.7  (Discharge when battery at 25.7v or more)
                            PBCV24.0  (Switch back to 'grid' when battery below 24.0v)

Set other commands          PEa / PDa (Enable/disable buzzer)
                            PEb / PDb (Enable/disable overload bypass)
                            PEj / PDj (Enable/disable power saving)
                            PEu / PDu (Enable/disable overload restart);
                            PEx / PDx (Enable/disable backlight)
```

### Bonus: Lovelace Dashboard Files

_**Please refer to the screenshot above for an example of the dashboard.**_

I've included some Lovelace dashboard files in the `homeassistant/` directory, however you will need to need to adapt to your own Home Assistant configuration and/or name of the inverter if you have changed it in the `mqtt.json` config file.

Note that in addition to merging the sample Yaml files with your Home Assistant, you will need the following custom Lovelace cards installed if you wish to use my templates:

 - [vertical-stack-in-card](https://github.com/custom-cards/vertical-stack-in-card)
 - [circle-sensor-card](https://github.com/custom-cards/circle-sensor-card)
