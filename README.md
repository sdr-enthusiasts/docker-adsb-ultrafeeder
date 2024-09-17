# sdr-enthusiasts/docker-adsb-ultrafeeder

- [sdr-enthusiasts/docker-adsb-ultrafeeder](#sdr-enthusiastsdocker-adsb-ultrafeeder)
  - [Introduction](#introduction)
  - [Up-and-Running Quickly with `docker-compose`](#up-and-running-quickly-with-docker-compose)
  - [Ports](#ports)
  - [Runtime Environment Variables](#runtime-environment-variables)
    - [General Configuration](#general-configuration)
      - [Basic Ultrafeeder Parameters](#basic-ultrafeeder-parameters)
        - [Mandatory Parameters](#mandatory-parameters)
        - [Optional Parameters](#optional-parameters)
    - [Getting ADSB data to the Ultrafeeder](#getting-adsb-data-to-the-ultrafeeder)
      - [Connecting to an SDR or other hardware device](#connecting-to-a-sdr-or-other-hardware-device)
        - [Mandatory parameters](#mandatory-parameters-1)
        - [Optional/Additional Parameters](#optionaladditional-parameters)
        - [AutoGain for RTLSDR Devices](#autogain-for-rtlsdr-devices)
      - [Connecting to external ADSB data sources](#connecting-to-external-adsb-data-sources)
        - [All-in-One Configuration using `ULTRAFEEDER_CONFIG`](#all-in-one-configuration-using-ultrafeeder_config)
        - [Networking parameters](#networking-parameters)
        - [Feeding directly from Ultrafeeder](#feeding-directly-from-ultrafeeder)
        - [Alternate Configuration Method with `READSB_NET_CONNECTOR`](#alternate-configuration-method-with-readsb_net_connector)
      - [Optional Networking Parameters](#optional-networking-parameters)
      - [MLAT configuration](#mlat-configuration)
      - [MLAT troubleshooting](#mlat-troubleshooting)
      - [Configuring the built-in MLAT Hub](#configuring-the-built-in-mlat-hub)
    - [Web Gui (`tar1090`) Configuration](#web-gui-tar1090-configuration)
      - [`tar1090` Core Configuration](#tar1090-core-configuration)
      - [`tar1090` `config.js` Configuration - Title](#tar1090-configjs-configuration---title)
      - [`tar1090` `config.js` Configuration - Output](#tar1090-configjs-configuration---output)
      - [`tar1090` `config.js` Configuration - Map Settings](#tar1090-configjs-configuration---map-settings)
      - [`tar1090` `config.js` Configuration - Range Rings](#tar1090-configjs-configuration---range-rings)
      - [`tar1090` `config.js` Configuration - Expert](#tar1090-configjs-configuration---expert)
      - [`tar1090` `config.js` Configuration - Route Display](#tar1090-configjs-configuration---route-display)
    - [`graphs1090` Configuration](#graphs1090-configuration)
      - [`graphs1090` Environment Parameters](#graphs1090-environment-parameters)
      - [Enabling UAT data](#enabling-uat-data)
      - [Enabling AirSpy graphs](#enabling-airspy-graphs)
      - [Enabling Disk IO and IOPS data](#enabling-disk-io-and-iops-data)
      - [Configuring the Core Temperature graphs](#configuring-the-core-temperature-graphs)
      - [Reducing Disk IO for Graphs1090](#reducing-disk-io-for-graphs1090)
    - [`timelapse1090` Configuration](#timelapse1090-configuration)
  - [Updating your location with GPSD](#updating-your-location-with-gpsd)
    - [Basic Installation and Configuration of your GPS hardware and `gpsd` drivers](#basic-installation-and-configuration-of-your-gps-hardware-and-gpsd-drivers)
    - [Optional parameters regulating the restart of `mlat-client` when the location changes](#optional-parameters-regulating-the-restart-of-mlat-client-when-the-location-changes)
  - [Web Pages](#web-pages)
  - [Paths](#paths)
  - [Display of Metrix with Grafana and Prometheus/InfluxDB](#display-of-metrix-with-grafana-and-prometheusinfluxdb)
    - [Configuring Grafana](#configuring-grafana)
    - [Output from Ultrafeeder to Prometheus](#output-from-ultrafeeder-to-prometheus)
    - [Output from Ultrafeeder to InfluxDBv2](#output-from-ultrafeeder-to-influxdbv2)
  - [Message decoding introspection](#message-decoding-introspection)
  - [Minimalist setup](#minimalist-setup)
  - [Logging](#logging)
  - [Getting help](#getting-help)
  - [License and Trademarks](#license-and-trademarks)
    - [GPLv3 License](#gplv3-license)
    - [Trademarks](#trademarks)
  - [Acknowledgements](#acknowledgements)

## Introduction

`adsb-ultrafeeder™` is an ADS-B data collector container that can be used to:

- retrieve ADS-B data from your SDR or other device
- display it on a local map, including options to show tracks, heatmaps, and system performance graphs
- forward the data to one or more aggregators using BEAST/BEAST-REDUCE/BEAST-REDUCE-PLUS format
- send MLAT data to these aggregators
- receive and consolidate MLAT results data (built-in `mlathub`)
- Interface with external visualization tools such as Grafana using statistics data available in InfluxDB and Prometheus format

In order to accomplish this, the container makes use of the following underlying technologies:

- SDR-Enthusiasts™ [Docker Base-Image](https://github.com/sdr-enthusiasts/docker-baseimage)
- [Wiedehopf's branch of `readsb`](https://github.com/wiedehopf/readsb)
- Wiedehopf's [tar1090](https://github.com/wiedehopf/tar1090) graphical interface
- Wiedehopf's [graphs1090](https://github.com/wiedehopf/graphs1090)
- [MLAT Client](https://github.com/adsbxchange/mlat-client.git)

It builds and runs on `linux/amd64`, `linux/arm/v7 (linux/armhf)` and `linux/arm64` architectures.
![ultrafeeder container architecture](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder/assets/15090643/12b7f054-a77a-4c21-8f72-d0069cc9af84)

## Up-and-Running Quickly with `docker-compose`

- An example [`docker-compose.yml`](docker-compose.yml) file can be found in this repository.
- The accompanying environment variable values are defined in the [`.env`](.env) file in this repository

Once you have [installed Docker](https://github.com/sdr-enthusiasts/docker-install), you can follow these lines of code to get up and running in very little time:

```bash
sudo mkdir -p -m 777 /opt/adsb
cd /opt/adsb
wget https://raw.githubusercontent.com/sdr-enthusiasts/docker-adsb-ultrafeeder/main/docker-compose.yml
wget https://raw.githubusercontent.com/sdr-enthusiasts/docker-adsb-ultrafeeder/main/.env
```

Then edit the `docker-compose.yml` and `.env` files and make any changes as needed. Please configure ALL variables in `.env`:

```bash
nano docker-compose.yml
nano .env
```

Finally, bring up the stack. This may take a minute as it will automatically download the container and start it up:

```bash
docker compose up -d
```

## Ports

Some common ports are as follows (which may or may not be in use depending on your configuration). You can override the port mappings with the parameters shown in the [Optional Networking Parameters section](#optional-networking-parameters).

The general principle behind the port numbering, is:

- `30xxx` ports are connected to the main instance `readsb` that decodes and processes the SDR data
- `31xxx` ports are connected to the MLAT Hub
- `92xx` ports are for Prometheus statistics output
- `80` contains the Tar1090 web interface

| Port                        | Details                                            |
| --------------------------- | -------------------------------------------------- |
| `30001/tcp`                 | Raw protocol input                                 |
| `30002/tcp`                 | Raw protocol output                                |
| `30003/tcp`                 | SBS/Basestation protocol output                    |
| `32006/tcp`                 | SBS/Basestation protocol input                     |
| `30004/tcp`<br/>`30104/tcp` | Beast protocol input                               |
| `30005/tcp`                 | Beast protocol output                              |
| `30006/tcp`                 | Beast reduce protocol output                       |
| `30047/tcp`                 | Json position output                               |
| `31003/tcp`                 | MLATHUB SBS/Basestation protocol output            |
| `31004/tcp`                 | MLATHUB Beast protocol input                       |
| `31005/tcp`                 | MLATHUB Beast protocol output                      |
| `31006/tcp`                 | MLATHUB Beast-reduce protocol output               |
| `9273/tcp`                  | Prometheus web interface with data from `readsb`   |
| `9274/tcp`                  | Prometheus web interface with data from `Telegraf` |
| `80/tcp`                    | Tar1090 (map) web interface                        |

Any of these ports can be made available to the host system by using the `ports:` directive in your `docker-compose.yml`. The container's web interface is rendered to port `80` in the container. This can be mapped to a port on the host using the docker-compose `ports` directive. In the example [`docker-compose.yml`](docker-compose.yml) file, the container's Tar1090 interface is mapped to `8080` on the host system, and ports `9273-9274` are exposed as-is:

```yaml
    ports:
      - 8080:80               # to expose the web interface
      - 9273-9274:9273-9274   # to expose the statistics interface to Prometheus
```

Json position output:

- outputs an aircraft object for every new position received for an aircraft. The following parameters (which can be added with `READSB_EXTRA_ARGS`) control this output:
- `--net-json-port-interval` Set minimum interval between outputs per aircraft for TCP json output, default: 0.0 (every position)
- `--net-json-port-include-noposition` TCP json position output: include aircraft without position (state is sent for aircraft for every DF11 with CRC if the aircraft hasn't sent a position in the last 10 seconds and interval allowing)
- each json object will be on a new line
- <https://github.com/wiedehopf/readsb/blob/dev/README-json.md>

Aircraft.json:

- <https://github.com/wiedehopf/readsb/blob/dev/README-json.md>
- available on the same port as the web interface, example: `http://192.168.x.yy:8087/data/aircraft.json`

## Runtime Environment Variables

The sections below describe how to configure each part of the container functionality. Each section describes what's needed to come up with a minimally viable configuration, followed by additional / optional parameters that can also be set.

Note:

- to enable a parameter, you can set it to any of `1`, `true`, `on`, `enabled`, `enable`, `yes`, or `y`. In the table below, we'll simply use `true` for convenience.
- to disable a parameter, you can set it to anything else or simply leave it undefined.

### General Configuration

You need to make sure that the USB device can be accessed by the container. The best way to do so, is by adding the following to your `docker-compose.yml` file:

```yaml
    device_cgroup_rules:
      - 'c 189:* rwm'
...
    volumes:
      - /dev:/dev:rw
```

The advantage of doing this (over simply adding a `device:` directive pointing at the USB port) is that the construction above will automatically recover if you "hot plug" your dongle. ⚠️This feature requires a recent version of docker-compose (version >=2.3). Make sure your system is up to date if dongles are not found. ⚠️

#### Basic Ultrafeeder Parameters

##### Mandatory Parameters

The following parameters must be set (mandatory) for the container to function:

| Environment Variable   | Purpose                                                                                                        | Default |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- | ------- |
| `LAT` or `READSB_LAT`  | The latitude of your antenna. Use either parameter, but not both                                               |         |
| `LONG` or `READSB_LON` | The longitude of your antenna. Use either parameter, but not both                                              |         |
| `ALT` or `READSB_ALT`  | The altitude of your antenna above sea level. For example, `15m` or `45ft`                                     |         |
| `TZ`                   | Your local timezone in [TZ-database-name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) format |         |

##### Optional Parameters

| Environment Variable          | Description                                                                                                                      | Controls which `readsb` option | Default   |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | --------- |
| `ENABLE_TIMELAPSE1090`        | Optional / Legacy. Set to `true` to enable timelapse1090. Once enabled, can be accessed via <http://dockerhost:port/timelapse/>. | Unset                          |           |
| `READSB_EXTRA_ARGS`           | Optional, allows to specify extra parameters for readsb                                                                          | Unset                          |           |
| `READSB_DEBUG`                | Optional, used to set debug mode. `n`: network, `P`: CPR, `S`: speed check                                                       | Unset                          |           |
| `S6_SERVICES_GRACETIME`       | Optional, set to 30000 when saving traces / globe_history                                                                        | `3000`                         |           |
| `READSB_ENABLE_BIASTEE`       | Set to `true` to enable bias tee on supporting interfaces                                                                        |                                | Unset     |
| `READSB_RX_LOCATION_ACCURACY` | Accuracy of receiver location in metadata: 0=no location, 1=approximate, 2=exact (`HEYWHATSTHAT_PANORAMA_ID` also has location)  | `--rx-location-accuracy=<n>`   | `2`       |
| `READSB_HEATMAP_INTERVAL`     | Per plane interval for heatmap and replay (if you want to lower this, also lower json-trace-interval to this or a lower value)   | `--heatmap=<sec>`              | `15`      |
| `READSB_MAX_RANGE`            | Absolute maximum range for position decoding (in nm)                                                                             | `--max-range=<dist>`           | `450`     |
| `READSB_STATS_EVERY`          | Number of seconds between showing and resetting stats.                                                                           | `--stats-every=<sec>`          | Unset     |
| `READSB_STATS_RANGE`          | Set this to `true` to collect range statistics for polar plot.                                                                   | `--stats-range`                | Unset     |
| `READSB_RANGE_OUTLINE_HOURS`  | Change which past timeframe the range outline is based on                                                                        | `--range-outline-hours`        | `24`      |
| `READSB_EXTRA_ARGS`           | Optional, allows to specify extra parameters for readsb                                                                          |                                | Unset     |
| `S6_SERVICES_GRACETIME`       | Optional, set to 30000 when saving traces / globe_history                                                                        |                                | `3000`    |
| `LOGLEVEL`                    | `verbose` (all messages), `error` (errors only), `none` (minimal)                                                                |                                | `verbose` |
| `MLAT_STARTUP_STAGGER`        | mlat-client startup staggering for tidy logs (reduce for quicker startup)                                                        |                                | `15`      |
| `MAX_GLOBE_HISTORY`           | Maximum number of days that `globe_history` data (used to produce heatmaps and ptracks) is retained. Note - this parameter doesn't affect the data used to produce `graphs1090` statistics | | Unset |

`READSB_EXTRA_ARGS` just passes arguments to the commandline, you can check this file for more options for wiedehopf's readsb fork: <https://github.com/wiedehopf/readsb/blob/dev/help.h>

### Getting ADSB data to the Ultrafeeder

There are two ways to provide ADSB data to the Ultrafeeder:

- provide the container with access to an SDR or other hardware device that collects ADSB data
- allow the container to connect to a ADSB data source in Beast, Raw, or SBS format

These methods are not mutually exclusive - you can use both at the same time if you want.

#### Connecting to an SDR or other hardware device

If you want to connect your SDR to the container, here's how to do that:

##### Mandatory parameters

| Variable               | Description                                                                                                                           | Controls which `readsb` option | Default        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | -------------- |
| `READSB_DEVICE_TYPE`   | If using an SDR, set this to `rtlsdr`, `modesbeast`, `gnshulc` depending on the model of your SDR. If not using an SDR, leave un-set. | `--device-type=<type>`         | Unset          |
| `READSB_RTLSDR_DEVICE` | Select device by serial number.                                                                                                       | `--device=<serial>`            | Unset          |
| `READSB_BEAST_SERIAL`  | only when type `modesbeast` or `gnshulc` is used: Path to Beast serial device.                                                        | `--beast-serial=<path>`        | `/dev/ttyUSB0` |

##### Optional/Additional Parameters

| Variable            | Description                                                                                                                                 | Controls which `readsb` option | Default  |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | -------- |
| `READSB_GAIN`       | Set gain (in dB). Use `autogain` to have the container determine an appropriate gain, more on this below.                                   | `--gain=<db>`                  | Max gain |
| `READSB_RTLSDR_PPM` | Set oscillator frequency correction in PPM. See [Estimating PPM](https://github.com/sdr-enthusiasts/docker-readsb-protobuf/#estimating-ppm) | `--ppm=<correction>`           | Unset    |

##### AutoGain for RTLSDR Devices

If you have set `READSB_GAIN=autogain`, then the system will take signal strength measurements to determine the optimal gain. The AutoGain functionality is based on a (slightly) modified version of [Wiedehopf's AutoGain](https://github.com/wiedehopf/autogain). AutoGain will only work with `rtlsdr` style receivers.

Note that AutoGain is not related to the SDR's AGC setting (controlled with the `READSB_RTLSDR_ENABLE_AGC` variable). We do not recommend enabling AGC for Ultrafeeder or any other ADS-B decoder.

There are 2 distinct periods in which the container will attempt to figure out the gain:

- The initial period of 2 hours, in which an adjustment is done every 5 minutes
- The subsequent period, in which an adjustment is done once every day

Please note that in order for the initial period to complete, the container must run for 90 minutes without restarting.

When taking measurements, if the percentage of "strong signals" (i.e., ADSB messages with RSSI > 3 dB) is larger than 6%, AutoGain will reduce the receiver's gain by 1 setting. Similarly, if the percentage of strong signals is smaller than 2.5%, AutoGain will increment the receiver's gain by 1 setting. When AutoGain changes the gain value, the `readsb` component of the container will restart. This may show as a disconnect / reconnected in container logs.

We recommend running the initial period during times when there are a lot of planes overhead, so the system will get a good initial view of what signals look like when traffic is at its peak for your location. If you forgot to do this for any reason, feel free to give the AutoGain reset command (see below) during flights busy hour.

Although not recommended, you can change the measurement intervals and low/high cutoffs with these parameters:

| Environment Variable                  | Purpose                                                                                                       | Default |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------- |
| `READSB_AUTOGAIN_INITIAL_TIMEPERIOD`  | How long the Initial Time Period should last (in seconds)                                                     | `7200`  |
| `READSB_AUTOGAIN_INITIAL_INTERVAL`    | The measurement interval to optimize gain during the initial period of 90 minutes (in seconds)                | `300`   |
| `READSB_AUTOGAIN_SUBSEQUENT_INTERVAL` | The measurement interval to optimize gain during the subsequent period (in seconds)                           | `86400` |
| `READSB_AUTOGAIN_LOW_PCT`             | If the percentage of "strong signals" (stronger than 3dBFS RSSI) is below this number, gain will be increased | `2.5`   |
| `READSB_AUTOGAIN_HIGH_PCT`            | If the percentage of "strong signals" (stronger than 3dBFS RSSI) is above this number, gain will be decreased | `6.0`   |

If you need to reset AutoGain and start over determining the gain, you can do so with this command:

```bash
docker exec -it ultrafeeder /usr/local/bin/autogain1090 reset
```

#### Connecting to external ADSB data sources

In addition to (or instead of) connecting to an SDR or hardware device to get ADSB data, the container also supports ingesting or sending data from a TCP port. Here are some parameters that you need to configure if you want to make this happen:

##### All-in-One Configuration using `ULTRAFEEDER_CONFIG`

`ULTRAFEEDER_CONFIG` is a new parameter that can be used instead of separately defining `READSB_NET_CONNECTOR`, `MLAT_NET_CONNECTOR`, `MLATHUB_NET_CONNECTOR`/`MLATHUB_CONFIG`. These legacy parameters will still work; however, we wanted to provide a single parameter that enables configuration of incoming and outgoing ADSB data, MLAT-client data, and MLATHUB data.

Note that `ULTRAFEEDER_CONFIG` and `ULTRAFEEDER_NET_CONNECTOR` can be used interchangeably; in this documentation, we'll use `ULTRAFEEDER_CONFIG` as an example.

`ULTRAFEEDER_CONFIG` syntax:

The ULTRAFEEDER_CONFIG parameter can have multiple config strings, separated by a `;`. Please note that the config strings cannot contain `;` or `,` -- undefined things may happen if these characters are present.

```yaml
- ULTRAFEEDER_CONFIG=adsb,host,port,protocol[,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX][,extra-arguments]
...or...
- ULTRAFEEDER_CONFIG=mlat,host,port[,return_port][,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX][,extra-arguments]
...or to retrieve MLAT data from a remote receiver...
- ULTRAFEEDER_CONFIG=mlat,host,port[,return_port][,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX][,input_connect=remote-host:port,lat=xx.xxxx,lon=yy.yyyy,alt=zzz][,extra-arguments]
...or...
- ULTRAFEEDER_CONFIG=mlathub,host,port,protocol[,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX][,extra-arguments]
```

- To connect to an external ADSB (for input or output), UAT, or MLAT results source, use `- ULTRAFEEDER_CONFIG=adsb,host,port,protocol[,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX][,extra-arguments]`
- To connect and send data to an MLAT Server, use `- ULTRAFEEDER_CONFIG=mlat,host,port[,return_port][,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX][,name=Friendly_Name-123][,input_connect=remote-host:port,lat=xx.xxxx,lon=yy.yyyy,alt=zzz][,extra-arguments]`. For the optional parts in this structure, see [MLAT configuration](#mlat-configuration). Note - any MLAT results data received from the MLAT Server will automatically be aggregated in an [MLAT Hub](#configuring-the-built-in-mlat-hub) and shared with `tar1090`
- To add MLAT results from additional MLAT Servers not configured with Ultrafeeder (for example, MLAT results from FlightRadar24 or FlightAware/piaware), use `- ULTRAFEEDER_CONFIG=mlathub,host,port,protocol[,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX][,extra-arguments]`. You can further configure this MLAT Hub as described in the section [Configuring the built-in MLAT Hub](#configuring-the-built-in-mlat-hub)

In the above configuration strings:

- `host` is an IP address. Specify an IP/hostname/containername for incoming or outgoing connections.
- `port` and `return_port` are TCP port numbers
- `protocol` can be one of the following:
  - `beast_reduce_out`: Beast-format output with lower data throughput (saves bandwidth and CPU)
  - `beast_reduce_plus_out`: Beast-format output with extra data (UUID). This is the preferred format when feeding the "new" aggregator services
  - `beast_out`: Beast-format output
  - `beast_in`: Beast-format input
  - `raw_out`: Raw output
  - `raw_in`: Raw input
  - `sbs_out`: SBS-format output
  - `vrs_out`: SBS-format output
  - `uat_in`: "special" RAW format input as generated by the `dump978` container on port 30978. It is advisable to use this protocol and port to get UAT data from dump978, for example: `- ULTRAFEEDER_CONFIG=adsb,dump978,30978,uat_in`
- `uuid` is a Universally Unique Identifier. You can reuse the one you generated for AdsbExchange, or you can generate a new one with this Linux command: `cat /proc/sys/kernel/random/uuid`. If omitted, it will use the `UUID` environment parameter, or if that one doesn't exist, it will leave the field empty.
- `name` is a friendly name (containing any character of the set \[A-Za-z0-9_-\] - do not use any spaces, quotes, or other non-alphanumeric characters!) that will be sent to the MLAT Server, used to identify the station by name. If omitted, it will use the `MLAT_USER` parameter, or if that one doesn't exist, it will leave the field empty.

##### Networking parameters

| Environment Variable | Purpose                                                                                                                                                                                                                                                                               | Default |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `BEASTHOST`          | IP/Hostname of a Mode-S/Beast provider (`dump1090`/`readsb`)                                                                                                                                                                                                                          |         |
| `BEASTPORT`          | TCP port number of Mode-S/Beast provider (`dump1090`/`readsb`)                                                                                                                                                                                                                        | `30005` |
| `MLATHOST`           | Legacy parameter. IP/Hostname of an MLAT provider (`mlat-client`). Note - using this parameter will not make the MLAT data part of the consolidated mlathub. The preferred way of ingesting MLAT results is using the `mlathub` functionality of the container, see below for details |         |
| `MLATPORT`           | Legacy parameter used with `MLATHOST`. TCP port number of an MLAT provider (`mlat-client`)                                                                                                                                                                                            | 30105   |

##### Feeding directly from Ultrafeeder

There are several aggregators, both non-profit and commercial, that can directly be sent data from ultrafeeder without the need for an additional feeder container. We have added them in the example `docker-compose.yml` snippet above. Here is a partial list of these aggregators. All of them use the `beast_reduce_plus` format for feeding ADSB data, and `mlat-client` for feeding MLAT:

| Name            | (C)ommercial/<br/>(N)on-profit | Description                                               | Feed details                                                                               |
| --------------- | ------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Airplanes.live  | N                              | Run by volunteers that used to be related to adsbexchange | adsb:`feed.airplanes.live` port `30004`<br/>mlat: `feed.airplanes.live` port `31090`       |
| ADSB.fi         | N                              | Run by a Finnish IT and aviation enthusiast | adsb:`feed.adsb.fi` port `30004`<br/>mlat: `feed.adsb.fi` port `31090`                     |
| ADSB.lol        | N                              | Run by an aviation enthusiast located in the Netherlands    | adsb:`in.adsb.lol` port `30004`<br/>mlat: `in.adsb.lol` port `31090`                       |
| Planespotters   | N                              | planespotters.net                                         | adsb:`feed.planespotters.net` port `30004`<br/>mlat: `mlat.planespotters.net` port `31090` |
| The Air Traffic | N                              | Run by an aviation enthusiast                               | adsb:`feed.theairtraffic.com` port `30004`<br/>mlat: `mlat.theairtraffic.com` port `31090` |
| AVDelphi        | N                              | Aviation data-science company (non-profit)                | adsb:`data.avdelphi.com` port `24999`<br/>mlat: no MLAT                                    |
| ADSB Exchange   | C                              | Large aggregator owned by JetNet                          | adsb:`feed1.adsbexchange.com` port `30004`<br/>mlat: `feed.adsbexchange.com` port `31090`  |
| RadarPlane      | N                              | Run by a few aviation enthusiasts in Canada and Portugal            | adsb: `feed.radarplane.com` port `30001`<br/>mlat: `feed.radarplane.com` port `31090`      |
| Fly Italy ADSB  | N                              | Run by a few aviation enthusiasts in Italy                    | adsb: `dati.flyitalyadsb.com` port `4905`<br/>mlat: `dati.flyitalyadsb.com` port `30100`   |
| AussieADSB | C | Small semi-commercial aggregator focused uniquely on Australia/Oceania. See <https://aussieadsb.com>. See below on how to configure a feed to them | adsb: `aussieadsb.com` port (varies)<br/>mlat: `aussieadsb.com` port `30000` |

When feeding AdsbExchange, Ultrafeeder will send statistics to adsbexchange.com by default. See the description of the `ADSBX_STATS` parameter on how to disable this.

To feed AussieADSB (Australia/Oceania only!), execute this command on your host and follow the instructions. You can also use this command to de-register your feeder, or to see its status:

```bash
bash <(wget -qO - https://raw.githubusercontent.com/sdr-enthusiasts/docker-adsb-ultrafeeder/dev/aussieadsb.sh)
```

##### Alternate Configuration Method with `READSB_NET_CONNECTOR`

Instead of (or in addition to) using `BEASTHOST`, you can also define ADSB data ingests using the `READSB_NET_CONNECTOR` parameter. This is the preferred way if you have multiple sources or destinations for your ADSB data. This variable allows you to configure incoming and outgoing connections. The variable takes a semicolon (`;`) separated list of `host,port,protocol[,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX]`, see the section [All-in-One Configuration using `ULTRAFEEDER_CONFIG`](#all-in-one-configuration-using-ultrafeeder_config) for explanation of these parameters.

NOTE: If you have a UAT dongle and use `dump978` to decode this, you should use `READSB_NET_CONNECTOR` to ingest UAT data from `dump978`. See example below

```yaml
    environment:
    ...
      - READSB_NET_CONNECTOR=dump978,30978,uat_in;...
    ...
```

#### Optional Networking Parameters

There are many optional parameters relating to the ingestion of data and the general networking functioning of the `readsb` program that implements this functionality.

| Variable                              | Description                                                                                                                                              | Controls which `readsb` option          | Default       |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------- | ------------- |
| `READSB_NET_API_PORT`                 | <https://github.com/wiedehopf/readsb/blob/dev/README-json.md#--net-api-port-query-formats>                                                                                                                                                                                     | `--net-api-port=<ports>`                | `30152`       |
| `READSB_ENABLE_API`                   | Adds nginx proxies api at /re-api. Use with extraargs --write-json-globe-index --tar1090-use-api to get fast map with many planes | various | disabled |
| `READSB_NET_BEAST_REDUCE_INTERVAL`    | BeastReduce position update interval, longer means less data (valid range: `0.000` - `14.999`)                                                                                                                                                                                 | `--net-beast-reduce-interval=<seconds>` | `0.5`         |
| `READSB_NET_BEAST_REDUCE_FILTER_DIST` | Restrict beast-reduce output to aircraft in a radius of X nmi                                                                                                                                                                                                                  | `--net-beast-reduce-filter-dist=<nmi>`  | Unset         |
| `READSB_NET_BEAST_REDUCE_FILTER_ALT`  | Restrict beast-reduce output to aircraft below X ft                                                                                                                                                                                                                            | `--net-beast-reduce-filter-alt=<ft>`    | Unset         |
| `READSB_NET_BR_OPTIMIZE_FOR_MLAT`     | BeastReduce: Keep messages relevant to mlat-client                                                                                                                                                                                                                             | `--net-beast-reduce-optimize-for-mlat`  | Unset         |
| `READSB_NET_BEAST_REDUCE_OUT_PORT`    | TCP BeastReduce output listen ports (comma separated)                                                                                                                                                                                                                          | `--net-beast-reduce-out-port=<ports>`   | Unset         |
| `READSB_NET_BEAST_INPUT_PORT`         | TCP Beast input listen ports                                                                                                                                                                                                                                                   | `--net-bi-port=<ports>`                 | `30004,30104` |
| `READSB_NET_BEAST_OUTPUT_PORT`        | TCP Beast output listen ports                                                                                                                                                                                                                                                  | `--net-bo-port=<ports>`                 | `30005`       |
| `READSB_NET_BUFFER`                   | TCP buffer size 64Kb \* (2^n)                                                                                                                                                                                                                                                  | `--net-buffer=<n>`                      | `2` (256Kb)   |
| `READSB_NET_RAW_OUTPUT_INTERVAL`      | TCP output flush interval in seconds (maximum output buffer delay).                                                                                                                                                                                                            | `--net-ro-interval=<seconds>`           | `0.05`        |
| `READSB_NET_RO_INTERVAL_BEAST_REDUCE` | TCP output flush interval in seconds for beast reduce outputs (maximum output buffer delay).                                                                                                                                                                                   | `--net-ro-interval-beast-reduce=<secs>  | `0.12`        |
| `READSB_NET_RAW_OUTPUT_SIZE`          | TCP output flush size (maximum amount of internally buffered data before writing to network).                                                                                                                                                                                  | `--net-ro-size=<size>`                  | `1280`        |
| `READSB_NET_CONNECTOR_DELAY`          | Outbound re-connection delay.                                                                                                                                                                                                                                                  | `--net-connector-delay=<seconds>`       | `30`          |
| `READSB_NET_HEARTBEAT`                | TCP heartbeat rate in seconds (0 to disable).                                                                                                                                                                                                                                  | `--net-heartbeat=<rate>`                | `35`          |
| `READSB_NET_RAW_INPUT_PORT`           | TCP raw input listen ports.                                                                                                                                                                                                                                                    | `--net-ri-port=<ports>`                 | `30001`       |
| `READSB_NET_RAW_OUTPUT_PORT`          | TCP raw output listen ports.                                                                                                                                                                                                                                                   | `--net-ro-port=<ports>`                 | `30002`       |
| `READSB_NET_SBS_INPUT_PORT`           | TCP BaseStation input listen ports.                                                                                                                                                                                                                                            | `--net-sbs-in-port=<ports>`             | Unset         |
| `READSB_NET_SBS_OUTPUT_PORT`          | TCP BaseStation output listen ports.                                                                                                                                                                                                                                           | `--net-sbs-port=<ports>`                | `30003`       |
| `READSB_NET_SBS_DISABLE_REDUCE`       | Disable application of "reduce" logic to SBS/BaseStation output. (By default, this is enabled)                                                                                                                                                                                 | `--net-sbs-reduce`                      | Unset         |
| `REASSB_NET_VERBATIM`                 | Set this to `true` to forward messages unchanged.                                                                                                                                                                                                                              | `--net-verbatim`                        | Unset         |
| `READSB_NET_VRS_PORT`                 | TCP VRS JSON output listen ports.                                                                                                                                                                                                                                              | `--net-vrs-port=<ports>`                | Unset         |
| `READSB_WRITE_STATE_ONLY_ON_EXIT`     | if set to anything, it will only write the status range outlines, etc. upon termination of `readsb`                                                                                                                                                                            | `--write-state-only-on-exit`            | Unset         |
| `READSB_JSON_INTERVAL`                | Update interval for the webinterface in seconds / interval between aircraft.json writes                                                                                                                                                                                        | `--write-json-every=<sec>`              | `1.0`         |
| `READSB_JSON_TRACE_INTERVAL`          | Per plane interval for json position output and trace interval for globe history                                                                                                                                                                                               | `--json-trace-interval=<sec>`           | `15`          |
| `READSB_FORWARD_MLAT_SBS`             | If set to anything, it will include MLAT results in the SBS/BaseStation output. This may be desirable if you feed SBS data to applications like [VRS](https://github.com/sdr-enthusiasts/docker-virtualradarserver) or [PlaneFence](https://github.com/kx1t/docker-planefence) | `--forward_mlat_sms` | Unset                                   |
| `UUID`                                | Sets the UUID that is sent on the `beast_reduce_plus` port if no individual UUIDs have been defined with the `READSB_NET_CONNECTOR` parameter. Similarly, it's also used with `mlat-client` (see below) if no individual UUIDs have been set with the `MLAT_CONFIG` parameter. |                                         | Unset         |
| `ADSBX_STATS`                         | If set to `disabled`/`off`/`0`/`no`, and feeding to AdsbExchange has been configured, no special statistics will be shared with AdsbExchange. If unset or set to `enabled`/`on`/`1`/`yes`, statistics will be shared with AdsbExchange if they are configured as an aggregator |                                         | Unset         |

#### MLAT configuration

The Ultrafeeder contains a capability to send MLAT data to MLAT servers to be processed, and to receive the MLAT results and integrate those with an MLAT Hub and the `tar1090` map.
It will create a separate instance of `mlat-client` for each defined MLAT server. The parameters for these `mlat-client` instances is as follows:

```yaml
    environment:
    ...
      - ULTRAFEEDERCONFIG=
           ...
           mlat,mlat-server1.com,port1,return_port1,uuid=1234-5678-90123,inputconnect=remote_receiver1:30005,lat=12.3456,lon=45.6789,alt=18m,--arg1 hello --arg2 world;
           mlat,mlat-server2.com,port2,return_port2,uuid=5678-9012-34567,inputconnect=remote_receiver2:30005,-lat=12.3456,lon=45.6789,alt=18m,--arg1 hello-again --arg2 universe
    ...
      - MLAT_USER=some_friendly_user_name_using_only_alphanumeric_characters_without_spaces_or_quotes
```

where:

| Parameter         | Mandatory/Optional | Description                                                                                                                                                                                                                                                                        |
| ----------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mlat`            | Mandatory          | indicates that the line container MLAT-client configuration parameters                                                                                                                                                                                                             |
| `mlat-server.com` | Mandatory          | the domain name or ip address of the target MLAT server                                                                                                                                                                                                                            |
| `port`            | Mandatory          | the port (TCP or UDP) of the target MLAT server                                                                                                                                                                                                                                    |
| `return_port`     | Optional           | the port at which the MLAT results are made available in BEAST format. We recommend to sequentially number them starting at 39000                                                                                                                                                  |
| `uuid`            | Optional           | a unique user ID for this MLAT server instance. If included, the string must start with `uuid=`. If not included, it will use the value of the `UUID` parameter if it exists                                                                                                       |
| `input_connect`   | Optional           | a unique input connection in the form `input_connect=remotehost:port`, where `remotehost:` is the hostname or IP address and TCP port of your remote BEAST source. This can be used to connect to a remote Beast source and forward MLAT data to an MLAT server                    |
| `lat`             | Optional           | the latitude to be sent to the MLAT server in the form `lat=xx.xxxxx`. If omitted, the `LAT` / `READSB_LAT` parameter will be used. This is meant to be used in combination with `input_connect` for connecting to a remote Beast source and forward MLAT data to an MLAT server   |
| `lon`             | Optional           | the longitude to be sent to the MLAT server in the form `lon=xx.xxxxx`. If omitted, the `LONG` / `READSB_LON` parameter will be used. This is meant to be used in combination with `input_connect` for connecting to a remote Beast source and forward MLAT data to an MLAT server |
| `alt`             | Optional           | the altitude to be sent to the MLAT server in the form `alt=xx.xxxxx`. If omitted, the `ALT` / `READSB_ALT` parameter will be used. This is meant to be used in combination with `input_connect` for connecting to a remote Beast source and forward MLAT data to an MLAT server   |
| `extra-arguments` | Optional           | Any extra parameter you want to pass to the `mlat-client` program. Will be added verbatim to the command line                                                                                                                                                                      |

Note - the optional parameters can be given in any order.

The `MLAT_USER` parameter is passed to the MLAT Client and server, and will show up as a "friendly" name on MLAT related stats at your MLAT aggregator. This parameter can only contain alphanumeric (a-z, A-Z, 0-9) characters, dashes (-), or underscores (_).

#### MLAT troubleshooting

Sometimes, MLAT appears not to be working correctly and you will see messages with high `bad_sync_timeout` values, like this:

```text
[2024-06-29 11:31:20.385][mlat-client][in.adsb.lol] peer_count:  15 outlier_percent: 4.6 bad_sync_timeout: 870
```

Here are a few things you may want to try to fix this:

- Ensure your longitude, latitude, and altitude are ACCURATE
- Make sure your device's clock is synced continuously with a reliable NTP service. We recommend `chronyd` over `systemd.timesyncd`
- Do not try to send MLAT data from a centralized instance when you are using a remote receiver. Instead, feed MLAT directly from the remote station
- On Raspberry Pi 3/3B+, disable HealthCheck by adding the following to the ultrafeeder service section in your `docker-compose.yml` file. (This has to do with docker resource spikes that mess with MLAT timing on slower machines like the Pi3/3B+) :

  ```yaml
    ultrafeeder:
    ...
      healthcheck:
        disable: true
  ```

- MLAT often fails when you run your receiver on a Virtual Machine rather than directly on the hardware. Avoid virtual machines (including ProxMox and container-in-container setups) or disable MLAT on them
- For FlightAware MLAT, make sure that your location and altitude are PRECISELY defined in your dashboard on the FlightAware website
- Never, ever, ever resend MLAT results back to ADSB or MLAT aggregators. Please DO NOT. This will ensure your data is discarded and may get you banned from the aggregator
- If you feed your data to multiple aggregators, please do not enable MLAT for FlightRadar24 (per their request). Note that MLAT for FR24 using our containerized setup is disabled by default

#### Configuring the built-in MLAT Hub

An "MLAT Hub" is an aggregator of MLAT results from several sources. Since the container is capable of sending MLAT data to multiple ADSB aggregators (like adsb.lol/fi/one, etc), we built in a capability to:

- collect the MLAT results from all of these services
- ingest MLAT results from other containers (FlightAware, Radarbox, etc.)
- make the consolidated MLAT results available on a port in Beast or SBS (BaseStation) format
- create outbound connections using any supported format to send your Beast data wherever you want

Note - due to design limitations of `readsb`, the `tar1090` graphical interface will by default ONLY show MLAT results from the aggregators/MLAT sources that were defined with the `MLAT_NET_CONNECTOR` or `ULTRAFEEDER_CONFIG=mlat,...` parameters. If you want to show any MLAT results from sources that have their own feeder containers (for example, those from `piaware`), you should add these sources like this:

```yaml
   - ULTRAFEEDER_CONFIG=mlathub,host,port,protocol;
```

Where:

- `host` is the hostname where the `MLAT results` are coming from. This can be another container name (e.g., `piaware`) or the IP address of your machine on which `mlat-client` is running. Note -- this is NOT the hostname or IP of the MLAT Server or aggregator that processes the MLAT data
- `port` is the port on which the `mlat-client` on the `host` makes its results available
- `protocol` is the output protocol which is almost always `beast_in`

For example:

```yaml
   - ULTRAFEEDER_CONFIG=mlathub,piaware,30105,beast_in;
```

Generally, there is little else to configure, but there are a few parameters that you can set or change:

| Variable                        | Description                                                                                                                                                                                                                                                                        | Default if omitted |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `MLATHUB_SBS_OUT_PORT`          | TCP port where the consolidated MLAT results will be available in SBS (BaseStation) format                                                                                                                                                                                         | `31003`            |
| `MLATHUB_BEAST_IN_PORT`         | TCP port you where you can send additional MLAT results to, in Beast format                                                                                                                                                                                                        | `31004`            |
| `MLATHUB_BEAST_OUT_PORT`        | TCP port where consolidated MLAT results will be available in Beast format                                                                                                                                                                                                         | `31005`            |
| `MLATHUB_BEAST_REDUCE_OUT_PORT` | TCP port where consolidated MLAT results will be available in Beast format with reduced data rates                                                                                                                                                                                 | `31006`            |
| `MLATHUB_NET_CONNECTOR`         | (Obsolete, please use `ULTRAFEEDER_CONFIG=mlathub,...` instead.) List of semi-colon (`;`) separated IP or host, port, and protocols where MLATHUB will connect to ingest or send MLAT data. It follows the same syntax as described in the [`READSB_NET_CONNECTOR` syntax section](#alternate-configuration-method-with-readsb_net_connector) above | Unset              |
| `MLATHUB_DISABLE`               | If set to `true`, the MLATHUB will be disabled even if there are `mlat-client`s running in the container                                                                                                                                                                           | Unset              |
| `MLATHUB_ENABLE`                | If set to `true`, the MLATHUB will be enabled even if there are no `mlat-client`s running in the container                                                                                                                                                                         | Unset              |

### Web Gui (`tar1090`) Configuration

The Container creates an interactive web interface displaying the aircraft, based on Wiedehopf's widely used [tar1090](https://github.com/wiedehopf/tar1090) software.

The web interface is rendered to port `80` in the container. This can be mapped to a port on the host using the docker-compose `ports` directive.

All of the variables below are optional.

Note - due to design limitations of `readsb`, the `tar1090` graphical interface will by default ONLY show MLAT results from the aggregators/MLAT sources that were defined with the `MLAT_NET_CONNECTOR` parameter. If you want to show any additional MLAT results (for example, those from `piaware`), you should add a separate `READSB_NET_CONNECTOR` entry for them.

#### `tar1090` Core Configuration

| Environment Variable       | Purpose                                                                                                                                                                                            | Default              |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| `READSB_JSON_INTERVAL`     | Update data update interval for the webinterface in seconds                                                                                                                                        | `1.0`                |
| `UPDATE_TAR1090`           | At startup update tar1090 and tar1090db to the latest versions                                                                                                                                     | `true`               |
| `INTERVAL`                 | Interval at which the track history is saved                                                                                                                                                       | `8`                  |
| `HISTORY_SIZE`             | How many points in time are stored in the track history                                                                                                                                            | `450`                |
| `ENABLE_978`               | Change to yes to enable UAT/978 display in `tar1090`. This will also enable UAT-specific graphs in graphs1090                                                                                      | `no`                 |
| `URL_978`                  | The URL needs to point at where you would normally find the skyview978 webinterface, for example `http://192.168.0.29/skyaware978`. Note -- do not use `localhost` or `127.0.0.1                   |                      |
| `GZIP_LVL`                 | `1`-`9` are valid, lower lvl: less CPU usage, higher level: less network bandwidth used when loading the page                                                                                      | `3`                  |
| `PTRACKS`                  | Shows the last `$PTRACKS` hours of traces you have seen at the `?pTracks` URL                                                                                                                      | `8`                  |
| `TAR1090_FLIGHTAWARELINKS` | Set to `true` to enable FlightAware links in the web interface                                                                                                                                     | `null`               |
| `TAR1090_ENABLE_AC_DB`     | Set to `true` to enable extra information, such as aircraft type and registration, to be included in in `aircraft.json` output. Will use more 50 MB extra memory                                   | `false`              |
| `TAR1090_DB_LONGTYPE`      | Set to `false` to remove the "desc", "ownOp" and "year" fields from `aircraft.json` when AC_DB is enabled.                                                                                         | `true`              |
| `HEYWHATSTHAT_PANORAMA_ID` | Your `heywhatsthat.com` panorama ID. See <https://github.com/wiedehopf/tar1090#heywhatsthatcom-range-outline> (will reveal exact location in the webinterface)                                     |                      |
| `HEYWHATSTHAT_ALTS`        | Comma separated altitudes for multiple outlines. Use no units or `ft` for feet, `m` for meters, or `km` for kilometers. Only integer numbers are accepted, no decimals please                      | `12192m` (=40000 ft) |
| `HTTP_ACCESS_LOG`          | Optional. Set to `true` to display HTTP server access logs.                                                                                                                                        | `false`              |
| `HTTP_ERROR_LOG`           | Optional. Set to `false` to hide HTTP server error logs.                                                                                                                                           | `true`               |
| `TAR1090_IMAGE_CONFIG_LINK` | An optional URL shown at the top of page, designed to be used for a link back to a configuration page. The token `HOSTNAME` in the link is replaced with the current host that tar1090 is accessed on. | `null`                       |
| `TAR1090_IMAGE_CONFIG_TEXT` | Text to display for the config link                                                                                                                                                                    | `null`                       |
| `TAR1090_DISABLE`           | Set to `true` to disable the web server and all websites (including the map, `graphs1090`, `heatmap`, `pTracks`, etc.)                                                                                 | Unset                        |
| `READSB_ENABLE_HEATMAP`    | Set to `true` or leave unset to enable the HeatMap function available at `http://myip/?Heatmap`; set to `false` to disable the HeapMap function | `true` (enabled) |
| `TAR1090_AISCATCHER_SERVER` | If you want to show vessels from your AIS-Catcher instance on the map, put the (externally reachable) URL of your AIS-Catcher or ShipFeeder website in this parameter (incl. `https://`). Note - if you are using "barebones" AIS-Catcher you should add `GEOJSON on` after the `-N` parameter on the `AIS-Catcher` command line. If you use [docker-shipfeeder](https://github.com/sdr-enthusiasts/docker-shipfeeder), no change is needed for that container | Empty |
| `TAR1090_AISCATCHER_REFRESH` | Refresh rate (in seconds) of reading vessels from your AIS-Catcher instance. Defaults to 15 (secs) if omitted | `15` |

- For documentation on the aircraft.json format see this page: <https://github.com/wiedehopf/readsb/blob/dev/README-json.md>
- TAR1090_ENABLE_AC_DB causes readsb to load the tar1090 database as a csv file from this repository: <https://github.com/wiedehopf/tar1090-db/tree/csv>

#### `tar1090` `config.js` Configuration - Title

| Environment Variable         | Purpose                                              | Default   |
| ---------------------------- | ---------------------------------------------------- | --------- |
| `TAR1090_PAGETITLE`          | Set the tar1090 web page title                       | `tar1090` |
| `TAR1090_PLANECOUNTINTITLE`  | Show number of aircraft in the page title            | `false`   |
| `TAR1090_MESSAGERATEINTITLE` | Show number of messages per second in the page title | `false`   |

#### `tar1090` `config.js` Configuration - Output

| Environment Variable   | Purpose                                                                                                                                                                                                                                          | Default    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| `TAR1090_DISPLAYUNITS` | The DisplayUnits setting controls whether nautical (ft, NM, knots), metric (m, km, km/h) or imperial (ft, mi, mph) units are used in the plane table and in the detailed plane info. Valid values are "`nautical`", "`metric`", or "`imperial`". | `nautical` |

#### `tar1090` `config.js` Configuration - Map Settings

| Environment Variable                        | Purpose                                                                                                                                                                                                                                                                                                                                                                    | Default           |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| `TAR1090_BINGMAPSAPIKEY`                    | Provide a Bing Maps API key to enable the Bing imagery layer. You can obtain a free key (with usage limits) at <https://www.bingmapsportal.com/> (you need a "basic key").                                                                                                                                                                                                 | `null`            |
| `TAR1090_DEFAULTCENTERLAT`                  | Default center (latitude) of the map. This setting is overridden by any position information provided by dump1090/readsb. All positions are in decimal degrees.                                                                                                                                                                                                            | `45.0`            |
| `TAR1090_DEFAULTCENTERLON`                  | Default center (longitude) of the map. This setting is overridden by any position information provided by dump1090/readsb. All positions are in decimal degrees.                                                                                                                                                                                                           | `9.0`             |
| `TAR1090_DEFAULTZOOMLVL`                    | The google maps zoom level, `0` - `16`, lower is further out.                                                                                                                                                                                                                                                                                                              | `7`               |
| `TAR1090_SITESHOW`                          | Display center marker. Setting this to false will NOT remove your location, see `READSB_RX_LOCATION_ACCURACY` for that.                                                                                                                                                                                                                                                    | `true`           |
| `TAR1090_SITELAT`                           | Center marker. If readsb provides a receiver location, that location is used and these settings are ignored. Position of the marker (latitude).                                                                                                                                                                                                                            | `45.0`            |
| `TAR1090_SITELON`                           | Center marker. If readsb provides a receiver location, that location is used and these settings are ignored. Position of the marker (longitude).                                                                                                                                                                                                                           | `9.0`             |
| `TAR1090_SITENAME`                          | The tooltip of the center marker.                                                                                                                                                                                                                                                                                                                                          | `My Radar Site`   |
| `TAR1090_RANGE_OUTLINE_COLOR`               | Colour for the range outline.                                                                                                                                                                                                                                                                                                                                              | `#0000DD`         |
| `TAR1090_RANGE_OUTLINE_WIDTH`               | Width for the range outline.                                                                                                                                                                                                                                                                                                                                               | `1.7`             |
| `TAR1090_RANGE_OUTLINE_COLORED_BY_ALTITUDE` | Range outline is coloured by altitude.                                                                                                                                                                                                                                                                                                                                     | `false`           |
| `TAR1090_RANGE_OUTLINE_DASH`                | Range outline dashing. Syntax `[L, S]` where `L` is the pixel length of the line, and `S` is the pixel length of the space.                                                                                                                                                                                                                                                | Unset             |
| `TAR1090_ACTUAL_RANGE_OUTLINE_COLOR`        | Colour for the actual range outline                                                                                                                                                                                                                                                                                                                                        | `#00596b`         |
| `TAR1090_ACTUAL_RANGE_OUTLINE_WIDTH`        | Width of the actual range outline                                                                                                                                                                                                                                                                                                                                          | `1.7`             |
| `TAR1090_ACTUAL_RANGE_OUTLINE_DASH`         | Dashed style for the actual range outline. Unset for solid line. `[5,5]` for a dashed line with 5 pixel lines and spaces in between                                                                                                                                                                                                                                        | Unset             |
| `TAR1090_MAPTYPE_TAR1090`                   | Which map is displayed to new visitors. Valid values for this setting are `osm`, `esri`, `carto_light_all`, `carto_light_nolabels`, `carto_dark_all`, `carto_dark_nolabels`, `gibs`, `osm_adsbx`, `chartbundle_sec`, `chartbundle_tac`, `chartbundle_hel`, `chartbundle_enrl`, `chartbundle_enra`, `chartbundle_enrh`, and only with bing key `bing_aerial`, `bing_roads`. | `carto_light_all` |
| `TAR1090_MAPDIM`                            | Default map dim state, true or false.                                                                                                                                                                                                                                                                                                                                      | `true`            |
| `TAR1090_MAPDIMPERCENTAGE`                  | The percentage amount of dimming used if the map is dimmed, `0`-`1`                                                                                                                                                                                                                                                                                                        | `0.45`            |
| `TAR1090_MAPCONTRASTPERCENTAGE`             | The percentage amount of contrast used if the map is dimmed, `0`-`1`                                                                                                                                                                                                                                                                                                       | `0`               |
| `TAR1090_DWDLAYERS`                         | Various map layers provided by the DWD geoserver can be added here. [Preview and available layers](https://maps.dwd.de/geoserver/web/wicket/bookmarkable/org.geoserver.web.demo.MapPreviewPage?1&filter=false). Multiple layers are also possible. Syntax: `dwd:layer1,dwd:layer2,dwd:layer3`                                                                              | `dwd:RX-Produkt`  |
| `TAR1090_LABELZOOM`                         | Displays aircraft labels only until this zoom level, `1`-`15` (values >`15` don't really make sense)                                                                                                                                                                                                                                                                       |                   |
| `TAR1090_LABELZOOMGROUND`                   | Displays ground traffic labels only until this zoom level, `1`-`15` (values >`15` don't really make sense)                                                                                                                                                                                                                                                                 |                   |

#### `tar1090` `config.js` Configuration - Range Rings

| Environment Variable          | Purpose                                                                                                                                                                                                                           | Default           |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| `TAR1090_RANGERINGS`          | `false` to hide range rings                                                                                                                                                                                                       | `true`            |
| `TAR1090_RANGERINGSDISTANCES` | Distances to display range rings, in miles, nautical miles, or km (depending settings value '`TAR1090_DISPLAYUNITS`'). Accepts a comma separated list of numbers (no spaces, no quotes).                                          | `100,150,200,250` |
| `TAR1090_RANGERINGSCOLORS`    | Colours for each of the range rings specified in `TAR1090_RANGERINGSDISTANCES`. Accepts a comma separated list of hex colour values, each enclosed in single quotes (e.g., `TAR1090_RANGERINGSCOLORS='#FFFFF','#00000'`). No spaces. | Unset             |
| `TAR1090_ENABLE_ACTUALRANGE`    | Set to `true` or leave unset to enable the outline of the actual range of your station on the map; set to `false` to disable the this outline | `true` (enabled) |

#### `tar1090` `config.js` Configuration - Expert

| Environment Variable         | Purpose                                              | Default   |
| ---------------------------- | ---------------------------------------------------- | --------- |
| `TAR1090_CONFIGJS_APPEND`   | Append arbitrary javascript code to config.js        | Unset     |

- In case a setting is available in tar1090 but not exposed via environment variable for this container
- For a list of possible settings, see <https://github.com/wiedehopf/tar1090/blob/master/html/config.js>
- Incorrect syntax or any capitalization errors will cause the map to not load, you have been warned!
- Example: `TAR1090_CONFIGJS_APPEND= MapDim=false; nexradOpacity=0.2;`
- In the environment section of a compose file you can generally use multiple lines like this:

```yaml
    environment:
    ...
      - TAR1090_CONFIGJS_APPEND=
        MapDim=false;
        nexradOpacity=0.2;
    ...
```

#### `tar1090` `config.js` Configuration - Route Display

| Environment Variable  | Purpose                                            | Default                               |
| --------------------- | -------------------------------------------------- | ------------------------------------- |
| `TAR1090_USEROUTEAPI` | Set to `true` to enable route lookup for callsigns | Unset                                 |
| `TAR1090_ROUTEAPIURL` | API URL used                                       | `https://api.adsb.lol/api/0/routeset` |

### `graphs1090` Configuration

#### `graphs1090` Environment Parameters

| Variable                                     | Description                                                                                                                               | Default        |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `GRAPHS1090_DARKMODE`                        | If set to `true`, `graphs1090` will be rendered in "dark mode".                                                                           | Unset          |
| `GRAPHS1090_RRD_STEP`                        | Interval in seconds to feed data into RRD files.                                                                                          | `60`           |
| `GRAPHS1090_SIZE`                            | Set graph size, possible values: `small`, `default`, `large`, `huge`, `custom`.                                                           | `custom`       |
| `GRAPHS1090_ALL_LARGE`                       | Make the small graphs as large as the big ones by setting to `yes`.                                                                       | `no`           |
| `GRAPHS1090_FONT_SIZE`                       | Font size (relative to graph size).                                                                                                       | `10.0`         |
| `GRAPHS1090_MAX_MESSAGES_LINE`               | Set to `true` to draw a reference line at the maximum message rate.                                                                       | Unset          |
| `GRAPHS1090_LARGE_WIDTH`                     | Defines the width of the larger graphs. (if size is set to custom)                                                                        | `1096`         |
| `GRAPHS1090_LARGE_HEIGHT`                    | Defines the height of the larger graphs. (if size is set to custom)                                                                       | `235`          |
| `GRAPHS1090_SMALL_WIDTH`                     | Defines the width of the smaller graphs. (if size is set to custom)                                                                       | `619`          |
| `GRAPHS1090_SMALL_HEIGHT`                    | Defines the height of the smaller graphs. (if size is set to custom)                                                                      | `324`          |
| `GRAPHS1090_DISK_DEVICE`                     | Defines which disk device (`mmc0`, `sda`, `sdc`, etc) is shown. Leave empty for default device                                            | Unset          |
| `GRAPHS1090_ETHERNET_DEVICE`                 | Defines which (wired) ethernet device (`eth0`, `enp0s`, etc) is shown. Leave empty for default device                                     | Unset          |
| `GRAPHS1090_WIFI_DEVICE`                     | Defines which (wireless) WiFi device (`wlan0`, `wlp3s0`, etc) is shown. Leave empty for default device                                    | Unset          |
| `GRAPHS1090_DISABLE`                         | Set to `true` to disable the entire GRAPHS1090 web page and associated data collection                                                    | Unset          |
| `GRAPHS1090_DISABLE_CHART_CPU`               | Set to `true` to disable the GRAPHS1090 CPU chart                                                                                         | Unset          |
| `GRAPHS1090_DISABLE_CHART_TEMP`              | Set to `true` to disable the GRAPHS1090 Temperature chart                                                                                 | Unset          |
| `GRAPHS1090_DISABLE_CHART_MEMORY`            | Set to `true` to disable the GRAPHS1090 Memory Utilization chart                                                                          | Unset          |
| `GRAPHS1090_DISABLE_CHART_NETWORK_BANDWIDTH` | Set to `true` to disable the GRAPHS1090 Network Bandwidth chart                                                                           | Unset          |
| `GRAPHS1090_DISABLE_CHART_DISK_USAGE`        | Set to `true` to disable the GRAPHS1090 Disk Usage chart                                                                                  | Unset          |
| `GRAPHS1090_DISABLE_CHART_DISK_IOPS`         | Set to `true` to disable the GRAPHS1090 Disk IOPS chart                                                                                   | Unset          |
| `GRAPHS1090_DISABLE_CHART_DISK_BANDWIDTH`    | Set to `true` to disable the GRAPHS1090 Disk Bandwidth chart                                                                              | Unset          |
| `GRAPHS1090_WWW_TITLE`                       | Set title for the web page (displayed in the browser title or tab bar)                                                                    | `graphs1090`   |
| `GRAPHS1090_WWW_HEADER`                      | Set header text for the web page                                                                                                          | `Perf. Graphs` |
| `GRAPHS1090_HIDE_SYSTEM`                     | Hide the system graphs and don't render them, don't collect system data                                                                   | `no`           |
| `GRAPHS1090_DEFAULT_APPEND`                  | Append to /etc/default/graphs1090, see <https://github.com/wiedehopf/graphs1090/blob/master/default>                                      | Unset          |
| `ENABLE_AIRSPY`                              | Optional, set to any non-empty value if you want to enable the special AirSpy graphs. See below for additional configuration requirements | Unset          |
| `URL_AIRSPY`                                 | Optional, set to the URL where the airspy stats are available, for example `http://airspy_adsb`                                           | Unset          |

#### Enabling UAT data

ADS-B over UAT data is transmitted in the 978 MHz band, and this is used in the USA only. To display the corresponding graphs, you should:

1. Set the following environment parameters:

```yaml
      - ENABLE_978=yes
      - URL_978=http://dump978/skyaware978
```

2. Install the [`docker-dump978` container](https://github.com/sdr-enthusiasts/docker-dump978). Note - only containers downloaded/deployed on/after Feb 8, 2023 will work.

Note that you *must* configure `URL_978` to point at a working skyaware978 website with `aircraft.json` data feed. This means that the URL `http://dump978/skyaware978/data/aircraft.json` must return valid JSON data to this `tar1090` container.

#### Enabling AirSpy graphs

Users of AirSpy devices can enable extra `graphs1090` graphs by configuring the following:

1. Set the following environment parameters:

```yaml
      - ENABLE_AIRSPY=yes
      - URL_AIRSPY=http://airspy_adsb
```

2. Install the [`airspy_adsb` container](https://github.com/sdr-enthusiasts/airspy_adsb). Note - only containers downloaded/deployed on/after May 9th, 2024 will work with this method.

#### Enabling Disk IO and IOPS data

To allow the container access to the Disk IO data, you should map the following volume:

```yaml
    volumes:
      - /proc/diskstats:/proc/diskstats:ro
      ...
```

#### Configuring the Core Temperature graphs

By default, the system will use the temperature available at Thermal Zone 0. This generally works well on Raspberry Pi devices, and no additional changes are needed.

On different devices, the Core Temperature is mapped to a different Thermal Zone. To ensure the Core Temperature graph works, follow these steps

First check out which Thermal Zone contains the temperature you want to monitor. On your host system, do this:

```bash
for i in /sys/class/thermal/thermal_zone* ; do echo "$i - $(cat ${i}/type) - $(cat ${i}/temp 2>/dev/null)"; done
```

Something similar to this will be show:

```bash
/sys/class/thermal/thermal_zone0 - acpitz - 25000
/sys/class/thermal/thermal_zone1 - INT3400 Thermal - 20000
/sys/class/thermal/thermal_zone2 - TSKN - 43050
/sys/class/thermal/thermal_zone3 - NGFF - 32050
/sys/class/thermal/thermal_zone4 - TMEM - 39050
/sys/class/thermal/thermal_zone5 - pch_skylake - 40500
/sys/class/thermal/thermal_zone6 - B0D4 - 54050
/sys/class/thermal/thermal_zone7 - iwlwifi_1 -
/sys/class/thermal/thermal_zone8 - x86_pkg_temp - 57000
```

Repeat this a few times to ensure that the temperature varies and isn't hardcoded to a value. In our case, either Thermal Zone 5 (`pch_skylake` is the Intel Core name) or Thermal Zone 8 (the temp of the entire SOC package) can be used. Once you have determined which Thermal Zone number you want to use, map it to a volume like this. Make sure that the part to the left of the first `:` reflects your Thermal Zone directory; the part to the right of the first `:` should always be `/sys/class/thermal/thermal_zone0:ro`.

Note that you will have to add `- privileged: true` capabilities to the container. This is less than ideal as it will give the container access to all of your system devices and processes. Make sure you feel comfortable with this before you do this.

```yaml
    privileged: true
    volumes:
      - /sys/class/thermal/thermal_zone8:/sys/class/thermal/thermal_zone0:ro
      ...
```

Note - on some systems (DietPi comes to mind), `/sys/class/thermal/` may not be available.

#### Reducing Disk IO for Graphs1090

Note - _this feature is still somewhat experimental. If you are really attached to your statistics/graphs1090 data, please make sure to back up your mapped drives regularly_

If you are using a Raspberry Pi or another type of computer with an SD card, you may already be aware that these SD cards have a limited number of write-cycles that will determine their lifespan. In other words - a common reason for SD card failure is excessive writes to it.

By the nature of having to log lots of data the `graphs1090` functionality writes a lot to the SD card. To reduce the number of write cycles, there are a few parameters you can set.

Enabling this functionality will cause `graphs1090` to temporarily write all data to volatile memory (`/run`) instead of persistent disk space (`/var/lib/collectd`). This data is backed up to persistent disk space in regular intervals and upon (graceful) shutdown of the container.

Note -- there is a chance that the data isn't written back in time (due to power failures, non-graceful container shutdowns, etc), in which case you may lose statistics data that has been generated since the last write-back.

The feature assumes that you have mapped `/var/lib/collectd` to a volume (to ensure data is persistent across container recreations), and `/run` as a `tmpfs` RAM disk, as shown below and also as per the [`docker-compose.yml` example](docker-compose.yml):

```yaml
    volumes:
      - /opt/adsb/ultrafeeder/globe_history:/var/globe_history
...
    tmpfs:
      - /run:exec,size=256M
...
```

| Environment Variable              | Purpose                                                                                        | Default |
| --------------------------------- | ---------------------------------------------------------------------------------------------- | ------- |
| `GRAPHS1090_REDUCE_IO=`           | Optional Set to `true` to reduce the write cycles for `graphs1090`                             | Unset   |
| `GRAPHS1090_REDUCE_IO_FLUSH_IVAL` | Interval (i.e. 1h, 6h, 24h, 1d, 2d) writing `graphs1090` data back to non-volatile storage     | `1d`    |

### `timelapse1090` Configuration

Legacy: **We recommend AGAINST enabling this feature** as it has been replaced with <http://dockerhost:port/?replay>. `timelapse1090` writes a lot of data to disk, which could shorten the lifespan of your Raspiberry Pi SD card. The replacement functionality is better and doesn't cause any additional disk writes.

| Environment Variable     | Purpose                                                                                                                         | Default |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `ENABLE_TIMELAPSE1090`   | Optional / Legacy. Set to `true` to enable timelapse1090. Once enabled, can be accessed via <http://dockerhost:port/timelapse/> | Unset   |
| `TIMELAPSE1090_INTERVAL` | Snapshot interval in seconds                                                                                                    | `10`    |
| `TIMELAPSE1090_HISTORY`  | Time saved in hours                                                                                                             | `24`    |

## Updating your location with GPSD

This feature enables you to deploy Ultrafeeder while you are moving around. It will read your current longitude/latitude/altitude from a GPS unit that is connected to `gpsd` on your host system, and ensure that the map will show your current location. It will also restart any `mlat-client` instances once it detects that you moved from your previous location.

### Basic Installation and Configuration of your GPS hardware and `gpsd` drivers

The simplest way of getting this to work is to acquire a ["VK163" USB GPS "Mouse"](https://a.co/d/0D7Tj0n), similar to the one in the link. You can connect this mouse to any USB port on your machine.

For this to work, you should install and configure GPSD to work on your host machine. The `DEVICES` parameter is probably correct as shown below, but you may want to double-check that data is received on that device (`cat /dev/ttyACM0`) and adjust it if needed:

```bash
sudo apt update && sudo apt install -y gpsd
cat << EOM | sudo tee /etc/default/gpsd
# Devices gpsd should collect to at boot time.
# They need to be read/writeable, either by user gpsd or the group dialout.
DEVICES="/dev/ttyACM0"
# Other options you want to pass to gpsd
GPSD_OPTIONS="-G"
# Automatically hot add/remove USB GPS devices via gpsdctl
USBAUTO="true"
EOM
cat << EOM | sudo tee /lib/systemd/system/gpsd.socket
[Unit]
Description=GPS (Global Positioning System) Daemon Sockets

[Socket]
ListenStream=/run/gpsd.sock
ListenStream=[::]:2947
ListenStream=0.0.0.0:2947
SocketMode=0600
BindIPv6Only=yes

[Install]
WantedBy=sockets.target
EOM
sudo systemctl daemon-reload
sudo systemctl restart gpsd gpsd.socket
```

Then, you can add the following values to `ultrafeeder` service settings in `docker-compose.yml`:

```yaml
services:
...
  ultrafeeder:
    ...
    extra_hosts:
      - "host.docker.internal:host-gateway"
    ...
    environment:
      ULTRAFEEDER-CONFIG=
        gpsd,host.docker.internal,2947;
    ...
```

Finally, restart the container with `docker compose up -d`

This will:

- install and configure `gpsd` (`/etc/default/gpsd`) so it makes GPS data available on the default TCP port 2947 of your host system
- configure the ultrafeeder docker container to read GPSD data
- configure the ultrafeeder container so the hostname `host.docker.internal` always resolves to the IP address of the underlying machine (where `gpsd` is running)

If you have any issues, readsb will use verbose output if you add the `GPSD_DEBUG=true` as an environment variable.

### Optional parameters regulating the restart of `mlat-client` when the location changes

The following parameters are all optional and are subject to change.  These variables should be added to the environment section of your docker-compose.yml. They will not work if entered into the .env file. You don't need to set them unless you want to change the default behavior.

| Environment Variable | Purpose | Default |
| -------------------- | ------- | ------- |
| `GPSD_MIN_DISTANCE` | Distance (in meters) that your station must move before it's considered moving (maximum 40 meters) | `20` (meters) |
| `GPSD_MLAT_WAIT` | The wait period (in seconds) your station must be stationary before mlat is started (minimum 90 seconds) | `90` (seconds) |
| `GPSD_CHECK_INTERVAL` | How often the container checks for updated location information. (minimum 5 seconds) | `30` (seconds) |

See example below:

```yaml
    environment:
    ...
      - GPSD_MIN_DISTANCE=20
      - GPSD_MLAT_WAIT=90
      - GPSD_CHECK_INTERVAL=30
    ...
```

## Web Pages

If you have configured the container as described above, you should be able to browse to the following web pages:
You should now be able to browse to:

- <http://dockerhost/> to access the tar1090 web interface.
- <http://dockerhost/?replay> to see a replay of past data
- <http://dockerhost/?heatmap> to see the heatmap for the past 24 hours
- <http://dockerhost/?heatmap&realHeat> to see a different heatmap for the past 24 hours
- <http://dockerhost/?pTracks> to see the tracks of all planes for the past 24 hours
- <http://dockerhost/graphs1090/> to see performance graphs

## Paths

No paths need to be mapped through to persistent storage. However, if you don't want to lose your range outline and aircraft tracks/history and heatmap / replay data on container restart, you can optionally map these paths:

| Path                                                                                                          | Purpose                                                                                                                          |
| ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `/opt/adsb/ultrafeeder/globe_history:/var/globe_history`                                                      | Holds range outline data, heatmap / replay data and traces if enabled. _Note: this data won't be automatically deleted, you will need to delete it eventually if you map this path._ |
| `/opt/adsb/ultrafeeder/timelapse1090:/var/timelapse1090`                                                      | Holds timelapse1090 data if enabled. (We recommend against enabling this feature, see above)                                     |
| `/opt/adsb/ultrafeeder/collectd:/var/lib/collectd`                                                            | Holds graphs1090 & performance data                                                                                              |
| `/proc/diskstats:/proc/diskstats:ro`                                                                          | Makes disk statistics available to `graphs1090`                                                                                  |
| `/sys/class/thermal/thermal_zone8:/sys/class/thermal/thermal_zone0:ro`                                        | Only needed on some systems to display the CPU temperature in `graphs1090`, see [here](#configuring-the-core-temperature-graphs) |

## Display of Metrix with Grafana and Prometheus/InfluxDB

When using the `:telegraf` tag, the image contains [Telegraf](https://docs.influxdata.com/telegraf/), which can be used to capture metrics from `ultrafeeder` if an output is enabled.

See [README-grafana.md](README-grafana.md) for detailed instruction on how to configure this.

**NOTE - READ CAREFULLY**: As of 27 April 2023, the `latest` image no longer contains Telegraf. If you want to send metrics to InfluxDB or Prometheus, please use this image:

```yaml
services:
  ultrafeeder:
    image: ghcr.io/sdr-enthusiasts/docker-ultrafeeder:telegraf
  ...
```

### Configuring Grafana

Please see the [separate instruction document](README-grafana.md) for step by step instructions on how to set up and configure a Grafana Dashboard with Prometheus. The sections below are provided as a reference.

### Output from Ultrafeeder to Prometheus

In order for Telegraf to serve a [Prometheus](https://prometheus.io) endpoint, the following environment variables can be used:

| Variable            | Description                                                              |
| ------------------- | ------------------------------------------------------------------------ |
| `PROMETHEUS_ENABLE` | Set to `true` for a Prometheus endpoint on `http://0.0.0.0:9273/metrics` |
| `PROMETHEUSPORT`    | TCP port for the Prometheus endpoint. Default value is `9273`            |

### Output from Ultrafeeder to InfluxDBv2

In order for Telegraf to output metrics to an [InfluxDBv2](https://docs.influxdata.com/influxdb/) time-series database, the following environment variables can be used:

| Variable            | Description                         |
| ------------------- | ----------------------------------- |
| `INFLUXDBV2_URL`    | The URL of the InfluxDB instance    |
| `INFLUXDBV2_TOKEN`  | The token for authentication        |
| `INFLUXDBV2_BUCKET` | Destination bucket to write into    |
| `INFLUXDBV2_ORG`    | InfluxDB Organization to write into |

## Message decoding introspection

You can look at individual messages and what information they contain, either for all or for an individual aircraft by hex:

```bash
# only for hex 3D3ED0
docker exec -it ultrafeeder /usr/local/bin/viewadsb --show-only 3D3ED0

# for all aircraft
docker exec -it ultrafeeder /usr/local/bin/viewadsb --no-interactive

# show position / CPR debugging for hex 3D3ED0
docker exec -it ultrafeeder /usr/local/bin/viewadsb --cpr-focus 3D3ED0
```

## Minimalist setup

If you want to use `ultrafeeder` _only_ as a SDR decoder but without any mapping or stats/graph websites, without MLAT connections or MLAT-hub, etc., for example to minimize CPU and RAM needs on a low CPU/memory single board computer, then do the following:

- in the `ULTRAFEEDER_CONFIG` parameter, remove any entry that starts with `mlat` or `mlathub`. This will prevent any `mlat-client`s or `mlathub` instances to be launched. If you still want to connect the `mlat-client`(s) to external MLAT servers but you don't want to run the overhead of a MLATHUB, you can leave any entries starting with `mlat` in the `ULTRAFEEDER_CONFIG` parameter, and set `MLATHUB_DISABLE=true`
- Set the parameter `TAR1090_DISABLE=true`. This will prevent the `nginx` webserver and any websites to be launched and no `collectd` (graphs1090) or `rrd` (ADSB message history) data to be collected or retained.
- Make sure to use `ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder:latest` and specifically NOT the `ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder:telegraf` label as Telegraf adds a LOT of resource use to the container

## Offline maps

There is the option to use some basic offline maps limited in zoom:

- Download  the tiles (don't install tar1090): <https://github.com/wiedehopf/adsb-wiki/wiki/offline-map-tiles-tar1090>
- Add a volume mapping so the container can access the tiles:

```yaml
    volumes:
        - /usr/local/share/osm_tiles_offline:/usr/local/share/osm_tiles_offline
```


## Logging

All logs are to the container's stdout and can be viewed with `docker logs -t [-f] container`.

## Getting help

Please feel free to [open an issue on the project's GitHub](https://github.com/sdr-enthusiasts/docker-tar1090/issues).

We also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.

## License and Trademarks

### GPLv3 License

Copyright (C) 2023-2024, Ramon F. Kolb kx1t, and other contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

### Trademarks

- `ultrafeeder`, `Ultrafeeder`, `docker-adsb-ultrafeeder` are Trademarks owned by Ramon F. Kolb and the SDR-Enthusiasts organization
- `SDR-Enthusiasts` and `SDR-E` are a Trademark owned by the SDR-Enthusiasts organization
- Other terms are trademarks of their respective owners

## Acknowledgements

- The [SDR-Enthusiasts team](https://github.com/sdr-enthusiasts) ([Mike Nye](https://github.com/mikenye), [Fred Clausen](https://github.com/fredclausen)) for all the foot and leg work done to create the base images on which the container is built
- [Wiedehopf](https://github.com/wiedehopf) for modifying, creating, maintaining, and adding features to many of the components of this container including [readsb](https://github.com/wiedehopf/readsb), [tar1090](https://github.com/wiedehopf/tar1090), [graphs1090](https://github.com/wiedehopf/graphs1090), [autogain](https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-gain-optimization-for-readsb-and-dump1090-fa), and many more components, and for helping debug the container whenever the need arose
- [John Norrbin](https://github.com/Johnex) for his ideas, testing, feature requests, more testing, nagging, pushing, prodding, and overall efforts to make this a high quality container and for the USB "hotplug" configuration
- The community at the [SDR-Enthusiasts Discord Server](https://discord.gg/sTf9uYF) for helping out, testing, asking questions, and generally driving to make this a better product
- Of course the Open Source community at large, including [Salvatore Sanfilippo](https://github.com/antirez) and [Oliver Jowett](https://github.com/mutability) who wrote the excellent base code for `dump1090` from which much of this package is derived
