# sdr-enthusiasts/docker-adsb-all-in-one

`adsb-all-in-one` is a ADS-B data collector container that can be used to:

* retrieve ADS-B data from your SDR or other device
* display it on a local map, including options to show tracks, heatmaps, and system performance graphs
* forward the data to one or more aggregators using BEAST/BEAST-REDUCE/BEAST-REDUCE-PLUS format
* send MLAT data to these aggregators
* receive and optionally consolidate MLAT results data (built-in `mlatuhb`)
* Interface with external visualization tools such as Grafana using statistics data available in InfluxDB and Prometheus format

In order to accomplish this, the container makes use of the following underlying technologies:

* SDR-Enthusiasts [Docker Base-Image](https://github.com/sdr-enthusiasts/docker-baseimage)
* [Wiedehopf's branch of `readsb`](https://github.com/wiedehopf/readsb)
* Wiedehopf's [tar1090](https://github.com/wiedehopf/tar1090) graphical interface
* Wiedehopf's [graphs1090](https://github.com/wiedehopf/graphs1090)
* [MLAT Client](https://github.com/adsbxchange/mlat-client.git)

It builds and runs on `linux/amd64`, `linux/arm/v7 (linux/armhf)` and `linux/arm64` architectures.

## Up-and-Running with `docker run`

```bash
docker run -d \
    --name=tar1090 \
    -p 8078:80 \
    -e TZ=<TIMEZONE> \
    -e BEASTHOST=<BEASTHOST> \
    -e MLATHOST=<MLATHOST> \
    -e LAT=xx.xxxxx \
    -e LONG=xx.xxxxx \
    -v /opt/adsb/tar1090/graphs1090:/var/lib/collectd \
    --tmpfs=/run:exec,size=64M \
    --tmpfs=/var/log \
    ghcr.io/sdr-enthusiasts/docker-tar1090:latest
```

Replacing `TIMEZONE` with your timezone, `BEASTHOST` with the IP address of a host that can provide Beast data, and `MLATHOST` with the IP address of a host that can provide MLAT data.

For example:

```bash
docker run -d \
    --name=tar1090 \
    -p 8078:80 \
    -e TZ=Australia/Perth \
    -e BEASTHOST=readsb \
    -e MLATHOST=adsbx \
    -e LAT=-33.33333 \
    -e LONG=111.11111 \
    -v /opt/adsb/tar1090/graphs1090:/var/lib/collectd \
    --tmpfs=/run:exec,size=64M \
    --tmpfs=/var/log \
    ghcr.io/sdr-enthusiasts/docker-tar1090:latest
```

You should now be able to browse to:

* <http://dockerhost:8078/> to access the tar1090 web interface
* <http://dockerhost:8078/?replay> to see a replay of past data
* <http://dockerhost:8078/?heatmap> to see the heatmap for the past 24 hours.
* <http://dockerhost:8078/?heatmap&realHeat> to see a different heatmap for the past 24 hours.
* <http://dockerhost:8078/graphs1090/> to see performance graphs

## Up-and-Running with `docker-compose`

An example `docker-compose.xml` file is below:

```yaml
version: '3.8'

services:
  tar1090:
    image: ghcr.io/sdr-enthusiasts/docker-adsb-all-in-one:latest
    tty: true
    container_name: adsb-all-in-one
    restart: always
    environment:
      - TZ=Australia/Perth
      - BEASTHOST=readsb
      - MLATHOST=adsbx
      - LAT=-33.33333
      - LONG=111.11111
    volumes:
      - /opt/adsb/tar1090/globe_history:/var/globe_history
      - /opt/adsb/tar1090/timelapse1090:/var/timelapse1090
      - /opt/adsb/tar1090/graphs1090:/var/lib/collectd
      - /proc/diskstats:/proc/diskstats:ro
    # - /run/airspy_adsb:/run/airspy_adsb
    ports:
      - 8078:80
    tmpfs:
      - /run:exec,size=64M
      - /var/log
```

You should now be able to browse to:

* <http://dockerhost:8078/> to access the tar1090 web interface.
* <http://dockerhost:8078/?replay> to see a replay of past data
* <http://dockerhost:8078/?heatmap> to see the heatmap for the past 24 hours.
* <http://dockerhost:8078/?heatmap&realHeat> to see a different heatmap for the past 24 hours.
* <http://dockerhost:8078/graphs1090/> to see performance graphs

*Note*: the example above excludes `MLATHOST` as `readsb` alone cannot provide MLAT data. You'll need a feeder container for this.

## Ports

Some common ports are as follows (which may or may not be in use depending on your configuration):

| Port | Details |
|------|---------|
| `30001/tcp` | Raw protocol input |
| `30002/tcp` | Raw protocol output |
| `30003/tcp` | SBS/Basestation protocol output |
| `32006/tcp` | SBS/Basestation protocol input |
| `30004/tcp` | Beast protocol input |
| `30005/tcp` | Beast protocol output |
| `30006/tcp` | Beast reduce protocol output |
| `30047/tcp` | Json position output |
| `31003/tcp` | MLATHUB SBS/Basestation protocol output |
| `31004/tcp` | MLATHUB Beast protocol input |
| `31005/tcp` | MLATHUB Beast protocol output |

Json position output:

* outputs an aircraft object for every new position received for an aircraft if the --json-trace-interval has elapsed for that aircraft
* to make it output every received position, set READSB_JSON_TRACE_INTERVAL to 0.1
* each json object will be on a new line
* <https://github.com/wiedehopf/readsb/blob/dev/README-json.md>

Aircraft.json:

* <https://github.com/wiedehopf/readsb/blob/dev/README-json.md>
* available on the same port as the web interface, example: `http://192.168.x.yy:8087/data/aircraft.json`

### Outgoing

This container will try to connect to the `BEASTHOST` on TCP port `30005` by default. This can be changed by setting the `BEASTPORT` environment variable.

If `MLATHOST` is set, this container will try to connecto the `MLATHOST` on TCP port `30105` by default. This can be changed to setting the `MLATPORT` environment variable.

### Incoming

This container accepts HTTP connections on TCP port `80` by default. You can change this with the container's port mapping. In the examples above, this has been changed to `8078`.

## Runtime Environment Variables

### Container Configuration

| Environment Variable | Purpose | Default |
|----------------------|---------|---------|
| `BEASTHOST` | Required. IP/Hostname of a Mode-S/Beast provider (`dump1090`/`readsb`) | |
| `BEASTPORT` | Optional. TCP port number of Mode-S/Beast provider (`dump1090`/`readsb`) | `30005` |
| `LAT` | Optional. The latitude of your antenna | |
| `LONG` | Optional. The longitude of your antenna | |
| `MLATHOST` | Optional. IP/Hostname of an MLAT provider (`mlat-client`) | |
| `MLATPORT` | Optional. TCP port number of an MLAT provider (`mlat-client`) | 30105 |
| `TZ` | Optional. Your local timezone in [TZ-database-name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) format | |
| `HEYWHATSTHAT_PANORAMA_ID` | Optional. Your `heywhatsthat.com` panorama ID. See <https://github.com/wiedehopf/tar1090#heywhatsthatcom-range-outline>. | |
| `HEYWHATSTHAT_ALTS` | Optional. Comma separated altitudes for multiple outlines. Use no units or `ft` for feet, `m` for meters, or `km` for kilometers. Only integer numbers are accepted, no decimals please | `12192m` (=40000 ft) |
| `HTTP_ACCESS_LOG` | Optional. Set to `true` to display HTTP server access logs. | `false` |
| `HTTP_ERROR_LOG` | Optional. Set to `false` to hide HTTP server error logs. | `true` |
| `READSB_MAX_RANGE` | Optional. Maximum range (in nautical miles). | `300` |
| `ENABLE_TIMELAPSE1090` | Optional / Legacy. Set to any value to enable timelapse1090. Once enabled, can be accessed via <http://dockerhost:port/timelapse/>. | Unset |
| `READSB_EXTRA_ARGS` | Optional, allows to specify extra parameters for readsb | Unset |
| `READSB_DEBUG` | Optional, used to set debug mode. `n`: network, `P`: CPR, `S`: speed check | Unset |
| `S6_SERVICES_GRACETIME` | Optional, set to 30000 when saving traces / globe_history | `3000` |
| `ENABLE_AIRSPY` | Optional, set to any non-empty value if you want to enable the special AirSpy graphs. See below for additional configuration requirements | Unset |

READSB_EXTRA_ARGS just passes arguments to the commandline, you can check this file for more options for wiedehofps readsb fork: <https://github.com/wiedehopf/readsb/blob/dev/help.h>

If you want to save historic data with tar1090, see a modified mode of operation at the end of the readme

### `tar1090` Configuration

All of the variables below are optional.

#### `tar1090` Core Configuration

| Environment Variable | Purpose | Default |
|----------------------|---------|---------|
| `READSB_JSON_INTERVAL` | Update data update interval for the webinterface in seconds | `1.0` |
| `UPDATE_TAR1090` | At startup update tar1090 and tar1090db to the latest versions | `true` |
| `INTERVAL` | Interval at which the track history is saved | `8` |
| `HISTORY_SIZE` | How many points in time are stored in the track history | `450` |
| `ENABLE_978` | Change to yes to enable UAT/978 display in `tar1090`. This will also enable UAT-specific graphs in graphs1090 | `no` |
| `URL_978` | The URL needs to point at where you would normally find the skyview978 webinterface | `http://127.0.0.1/skyaware978` |
| `GZIP_LVL` | `1`-`9` are valid, lower lvl: less CPU usage, higher level: less network bandwidth used when loading the page | `3` |
| `PTRACKS` | Shows the last `$PTRACKS` hours of traces you have seen at the `?pTracks` URL | `8` |
| `TAR1090_FLIGHTAWARELINKS` | Set to any value to enable FlightAware links in the web interface | `null` |
| `TAR1090_ENABLE_AC_DB` | Set to `true` to enable extra information, such as aircraft type and registration, to be included in in `aircraft.json` output. Will use more memory; use caution on older Pis or similiar devices. | `false` |

* For documentation on the aircraft.json format see this page: <https://github.com/wiedehopf/readsb/blob/dev/README-json.md>
* TAR1090_ENABLE_AC_DB causes readsb to load the tar1090 database as a csv file from this repository: <https://github.com/wiedehopf/tar1090-db/tree/csv>

#### `tar1090` `config.js` Configuration - Title

| Environment Variable | Purpose | Default |
|----------------------|---------|---------|
| `TAR1090_PAGETITLE` | Set the tar1090 web page title | `tar1090` |
| `TAR1090_PLANECOUNTINTITLE` | Show number of aircraft in the page title | `false` |
| `TAR1090_MESSAGERATEINTITLE` | Show number of messages per second in the page title | `false` |

#### `tar1090` `config.js` Configuration - Output

| Environment Variable | Purpose | Default |
|----------------------|---------|---------|
| `TAR1090_DISPLAYUNITS` | The DisplayUnits setting controls whether nautical (ft, NM, knots), metric (m, km, km/h) or imperial (ft, mi, mph) units are used in the plane table and in the detailed plane info. Valid values are "`nautical`", "`metric`", or "`imperial`". | `nautical` |

#### `tar1090` `config.js` Configuration - Map Settings

| Environment Variable | Purpose | Default |
|----------------------|---------|---------|
| `TAR1090_BINGMAPSAPIKEY` | Provide a Bing Maps API key to enable the Bing imagery layer. You can obtain a free key (with usage limits) at <https://www.bingmapsportal.com/> (you need a "basic key"). | `null` |
| `TAR1090_DEFAULTCENTERLAT` | Default center (latitude) of the map. This setting is overridden by any position information provided by dump1090/readsb. All positions are in decimal degrees. | `45.0` |
| `TAR1090_DEFAULTCENTERLON` | Default center (longitude) of the map. This setting is overridden by any position information provided by dump1090/readsb. All positions are in decimal degrees. | `9.0` |
| `TAR1090_DEFAULTZOOMLVL` | The google maps zoom level, `0` - `16`, lower is further out. | `7` |
| `TAR1090_SITESHOW` | Center marker. If dump1090 provides a receiver location, that location is used and these settings are ignored. Set to `true` to show a center marker. | `false` |
| `TAR1090_SITELAT` | Center marker. If dump1090 provides a receiver location, that location is used and these settings are ignored. Position of the marker (latitude). | `45.0` |
| `TAR1090_SITELON` | Center marker. If dump1090 provides a receiver location, that location is used and these settings are ignored. Position of the marker (longitude). | `9.0` |
| `TAR1090_SITENAME` | The tooltip of the center marker. | `My Radar Site` |
| `TAR1090_RANGE_OUTLINE_COLOR` | Colour for the range outline. | `#0000DD` |
| `TAR1090_RANGE_OUTLINE_WIDTH` | Width for the range outline. | `1.7` |
| `TAR1090_RANGE_OUTLINE_COLORED_BY_ALTITUDE` | Range outline is coloured by altitude. | `false` |
| `TAR1090_RANGE_OUTLINE_DASH` | Range outline dashing. Syntax `[L, S]` where `L` is the pixel length of the line, and `S` is the pixel length of the space. | Unset |
| `TAR1090_ACTUAL_RANGE_OUTLINE_COLOR` | Colour for the actual range outline | `#00596b` |
| `TAR1090_ACTUAL_RANGE_OUTLINE_WIDTH` | Width of the actual range outline | `1.7` |
| `TAR1090_ACTUAL_RANGE_OUTLINE_DASH`  | Dashed style for the actual range outline. Unset for solid line. `[5,5]` for a dashed line with 5 pixel lines and spaces in between | Unset |
| `TAR1090_MAPTYPE_TAR1090` | Which map is displayed to new visitors. Valid values for this setting are `osm`, `esri`,  `carto_light_all`, `carto_light_nolabels`, `carto_dark_all`, `carto_dark_nolabels`, `gibs`, `osm_adsbx`, `chartbundle_sec`, `chartbundle_tac`, `chartbundle_hel`, `chartbundle_enrl`, `chartbundle_enra`, `chartbundle_enrh`, and only with bing key `bing_aerial`, `bing_roads`. | `carto_light_all` |
| `TAR1090_MAPDIM` | Default map dim state, true or false. | `true` |
| `TAR1090_MAPDIMPERCENTAGE` | The percentage amount of dimming used if the map is dimmed, `0`-`1` | `0.45` |
| `TAR1090_MAPCONTRASTPERCENTAGE` | The percentage amount of contrast used if the map is dimmed, `0`-`1` | `0` |
| `TAR1090_DWDLAYERS` | Various map layers provided by the DWD geoserver can be added here. [Preview and available layers](https://maps.dwd.de/geoserver/web/wicket/bookmarkable/org.geoserver.web.demo.MapPreviewPage?1&filter=false). Multiple layers are also possible. Syntax: `dwd:layer1,dwd:layer2,dwd:layer3` | `dwd:RX-Produkt` |
| `TAR1090_LABELZOOM` | Displays aircraft labels only until this zoom level, `1`-`15` (values >`15` don't really make sense)|   |
| `TAR1090_LABELZOOMGROUND` | Displays ground traffic labels only until this zoom level, `1`-`15` (values >`15` don't really make sense) |   |

#### `tar1090` `config.js` Configuration - Range Rings

| Environment Variable | Purpose | Default |
|----------------------|---------|---------|
| `TAR1090_RANGERINGS` | `false` to hide range rings | `true` |
| `TAR1090_RANGERINGSDISTANCES` | Distances to display range rings, in miles, nautical miles, or km (depending settings value '`TAR1090_DISPLAYUNITS`'). Accepts a comma separated list of numbers (no spaces, no quotes). | `100,150,200,250` |
| `TAR1090_RANGERINGSCOLORS` | Colours for each of the range rings specified in `TAR1090_RANGERINGSDISTANCES`. Accepts a comma separated list of hex colour values, each enclosed in single quotes (eg `TAR1090_RANGERINGSCOLORS='#FFFFF','#00000'`). No spaces. | Blank |

### `timelapse1090` Configuration

Legacy: consider using <http://dockerhost:port/?replay> instead

| Environment Variable | Purpose | Default |
|----------------------|---------|---------|
| `TIMELAPSE1090_INTERVAL` | Snapshot interval in seconds | `10` |
| `TIMELAPSE1090_HISTORY` | Time saved in hours | `24` |

## Paths

No paths need to be mapped through to persistent storage. However, if you don't want to lose your range outline and aircraft tracks/history and heatmap / replay data on container restart, you can optionally map these paths:

| Path | Purpose |
|------|---------|
| `/var/globe_history` | Holds range outline data, heatmap / replay data and traces if enabled.  
*Note: this data won't be automatically deleted, you will need to delete it eventually if you map this path.* |
| `/var/timelapse1090` | Holds timelapse1090 data if enabled |
| `/var/lib/collectd`  | Holds graphs1090 & performance data |

### `readsb` Network Options

This container uses the readsb fork by wiedehopf as a backend to tar1090: <https://github.com/wiedehopf/readsb>

Where the default value is "Unset", `readsb`'s default will be used.

| Variable | Description | Controls which `readsb` option | Default |
|----------|-------------|--------------------------------|---------|
| `READSB_NET_CONNECTOR` | See "`READSB_NET_CONNECTOR` syntax" below. | `--net-connector=<ip,port,protocol>` | Unset |
| `READSB_NET_API_PORT` | <https://github.com/wiedehopf/readsb/blob/dev/README-json.md#--net-api-port-query-formats> | `--net-api-port=<ports>` | `30152` |
| `READSB_NET_BEAST_REDUCE_INTERVAL` | BeastReduce position update interval, longer means less data (valid range: `0.000` - `14.999`) | `--net-beast-reduce-interval=<seconds>` | `0.125` |
| `READSB_NET_BEAST_REDUCE_FILTER_DIST` | Restrict beast-reduce output to aircraft in a radius of X nmi | `--net-beast-reduce-filter-dist=<nmi>` | Unset |
| `READSB_NET_BEAST_REDUCE_FILTER_ALT` | Restrict beast-reduce output to aircraft below X ft | `--net-beast-reduce-filter-alt=<ft>` | Unset |
| `READSB_NET_BEAST_REDUCE_OUT_PORT` | TCP BeastReduce output listen ports (comma separated) | `--net-beast-reduce-out-port=<ports>` | Unset |
| `READSB_NET_BEAST_INPUT_PORT`| TCP Beast input listen ports | `--net-bi-port=<ports>` | `30004,30104` |
| `READSB_NET_BEAST_OUTPUT_PORT` | TCP Beast output listen ports | `--net-bo-port=<ports>` | `30005` |
| `READSB_NET_BUFFER` | TCP buffer size 64Kb * (2^n) | `--net-buffer=<n>` | `2` (256Kb) |
| `READSB_NET_RAW_OUTPUT_INTERVAL` | TCP output flush interval in seconds (maximum interval between two network writes of accumulated data). | `--net-ro-interval=<rate>` | `0.05` |
| `READSB_NET_RAW_OUTPUT_SIZE` | TCP output flush size (maximum amount of internally buffered data before writing to network). | `--net-ro-size=<size>` | `1200` |
| `READSB_NET_CONNECTOR_DELAY` | Outbound re-connection delay. | `--net-connector-delay=<seconds>` | `30` |
| `READSB_NET_HEARTBEAT` | TCP heartbeat rate in seconds (0 to disable). | `--net-heartbeat=<rate>` | `60` |
| `READSB_NET_RAW_INPUT_PORT` | TCP raw input listen ports. | `--net-ri-port=<ports>` | `30001` |
| `READSB_NET_RAW_OUTPUT_PORT` | TCP raw output listen ports. | `--net-ro-port=<ports>` | `30002` |
| `READSB_NET_SBS_INPUT_PORT` | TCP BaseStation input listen ports. | `--net-sbs-in-port=<ports>` | Unset |
| `READSB_NET_SBS_OUTPUT_PORT` | TCP BaseStation output listen ports. | `--net-sbs-port=<ports>` | `30003` |
| `REASSB_NET_VERBATIM` | Set this to any value to forward messages unchanged. | `--net-verbatim` | Unset |
| `READSB_NET_VRS_PORT` | TCP VRS JSON output listen ports. | `--net-vrs-port=<ports>` | Unset |
| `READSB_WRITE_STATE_ONLY_ON_EXIT` | if set to anything, it will only write the status range outlines, etc. upon termination of `readsb` | `--write-state-only-on-exit` | Unset |

#### `READSB_NET_CONNECTOR` syntax

This variable allows you to configure outgoing connections. The variable takes a semicolon (`;`) separated list of `ip,port,protocol`, where:

* `ip` is an IP address. Specify an IP/hostname/containername for outgoing connections.
* `port` is a TCP port number
* `protocol` can be one of the following:
  * `beast_out`: Beast-format output
  * `beast_in`: Beast-format input
  * `raw_out`: Raw output
  * `raw_in`: Raw input
  * `sbs_out`: SBS-format output
  * `vrs_out`: SBS-format output

For example, to pull in MLAT results (so the performance graphs in the web interface show MLAT numbers), you could do the following:

```yaml
    environment:
    ...
      - READSB_NET_CONNECTOR=piaware,30105,beast_in;adsbx,30105,beast_in;rbfeeder,30105,beast_in
    ...
```

### `readsb` General Options

Where the default value is "Unset", `readsb`'s default will be used.

| Variable | Description | Controls which `readsb` option | Default |
|----------|-------------|--------------------------------|---------|
| `READSB_ENABLE_BIASTEE` | Set to any value to enable bias tee on supporting interfaces | | Unset |
| `READSB_RX_LOCATION_ACCURACY` | Accuracy of receiver location in metadata: 0=no location, 1=approximate, 2=exact | `--rx-location-accuracy=<n>` | `2` |
| `READSB_JSON_INTERVAL` | Update interval for the webinterface in seconds / interval between aircraft.json writes | `--write-json-every=<sec>` | `1.0` |
| `READSB_JSON_TRACE_INTERVAL` | Per plane interval for json position output and trace interval for globe history | `--json-trace-interval=<sec>` | `15` |
| `READSB_HEATMAP_INTERVAL` | Per plane interval for heatmap and replay (if you want to lower this, also lower json-trace-interval to this or a lower value) | `--heatmap=<sec>` | `15` |
| `READSB_MAX_RANGE` | Absolute maximum range for position decoding (in nm) | `--max-range=<dist>` | `300` |
| `READSB_MLAT` | Set this to add timestamps to AVR / RAW output | `--mlat` | Unset |
| `READSB_STATS_EVERY` | Number of seconds between showing and resetting stats. | `--stats-every=<sec>` | Unset |
| `READSB_STATS_RANGE` | Set this to any value to collect range statistics for polar plot. | `--stats-range` |  Unset |
| `READSB_RANGE_OUTLINE_HOURS` | Change which past timeframe the range outline is based on | `--range-outline-hours` |  `24` |

## Configuring the built-in MLAT Hub

An "MLAT Hub" is an aggregator of MLAT results from several sources. Since the container is capable of sending MLAT data to multiple ADSB aggregators (like adsb.lol/fi/one, etc), we built in a capability to:

* collect the MLAT results from all of these services
* feed them back to the built-in `tar1090` graphical interface
* ingest MLAT results from other containers (FlightAware, Radarbox, etc.)
* make the consolidated MLAT results available on a port in Beast or SBS (BaseStation) format
* create outbound connections using any supported format to send your Beast data wherever you want

Generally, there is little to configure, but there are a few parameters that you can set or change:

| Variable | Description | Default if omitted|
|----------|-------------|--------------------------------|
| `MLATHUB_SBS_OUT_PORT` | TCP port where the consolidated MLAT results will be available in SBS (BaseStation) format | `31004` |
| `MLATHUB_BEAST_IN_PORT` | TCP port you where you can send additional MLAT results to, in Beast format | `31004` |
| `MLATHUB_BEAST_OUT_PORT` | TCP port where consolidated MLAT results will be available in Beast format | `31005` |
| `MLATHUB_NET_CONNECTOR` | List of semi-colon separated IP or host, port, and protocols where MLATHUB will connect to ingest or send MLAT data. It follows the same syntax as described in the "`READSB_NET_CONNECTOR` syntax " section above. | Unset |

## Message decoding introspection

You can look at individual messages and what information they contain, either for all or for an individual aircraft by hex:

```shell
# only for hex 3D3ED0
docker exec -it adsb-superfeeder /usr/local/bin/viewadsb --show-only 3D3ED0

# for all aircraft
docker exec -it adsb-superfeeder /usr/local/bin/viewadsb --no-interactive

# show position / CPR debugging for hex 3D3ED0
docker exec -it adsb-superfeeder /usr/local/bin/viewadsb --cpr-focus 3D3ED0
```

## Configuring `graphs1090`

### `graphs1090` Environment Parameters

| Variable | Description | Default |
|----------|-------------|---------|
| `GRAPHS1090_DARKMODE` | If set to any value, `graphs1090` will be rendered in "dark mode". | Unset |
| `GRAPHS1090_RRD_STEP` | Interval in seconds to feed data into RRD files. | `60` |
| `GRAPHS1090_SIZE` | Set graph size, possible values: `small`, `default`, `large`, `huge`, `custom`. | `default` |
| `GRAPHS1090_ALL_LARGE` | Make the small graphs as large as the big ones by setting to `yes`. | `no` |
| `GRAPHS1090_FONT_SIZE` | Font size (relative to graph size). | `10.0` |
| `GRAPHS1090_MAX_MESSAGES_LINE` | Set to any value to draw a reference line at the maximum message rate. | Unset |
| `GRAPHS1090_LARGE_WIDTH` | Defines the width of the larger graphs. | `1096` |
| `GRAPHS1090_LARGE_HEIGHT` | Defines the height of the larger graphs. | `235` |
| `GRAPHS1090_SMALL_WIDTH` | Defines the width of the smaller graphs. | `619` |
| `GRAPHS1090_SMALL_HEIGHT` | Defines the height of the smaller graphs. | `324` |
| `GRAPHS1090_DISK_DEVICE` | Defines which disk device (`mmc0`, `sda`, `sdc`, etc) is shown. Leave empty for default device | Unset |
| `GRAPHS1090_ETHERNET_DEVICE` | Defines which (wired) ethernet device (`eth0`, `enp0s`, etc) is shown. Leave empty for default device | Unset |
| `GRAPHS1090_WIFI_DEVICE` | Defines which (wireless) WiFi device (`wlan0`, `wlp3s0`, etc) is shown. Leave empty for default device | Unset |
| `GRAPHS1090_DISABLE` | Set to any value to disable the GRAPHS1090 web page | Unset |

### Enabling UAT data

ADS-B over UAT data is transmitted in the 978 MHz band, and this is used in the USA only. To display the corresponding graphs, you should:

1. Set the following environment parameters:

```yaml
  - ENABLE_978=yes
  - URL_978=http://dump978/skyaware978
```

2. Install the [`docker-dump978` container](https://github.com/sdr-enthusiasts/docker-dump978). Note - only containers downloaded/deployed on/after Feb 8, 2023 will work.

Note that you **must** configure `URL_978` to point at a working skyaware978 website with `aircraft.json` data feed. This means that the URL `http://dump978/skyaware978/data/aircraft.json` must return valid JSON data to this `tar1090` container.

### Enabling AirSpy graphs

Users of AirSpy devices can enable extra `graphs1090` graphs by configuring the following:

* Set the following environment parameter:

```yaml
      - ENABLE_AIRSPY=yes
```

* To provide the container access to the AirSpy statistics, map a volume in your `docker-compose.yml` file as follows:

```yaml
    volumes:
      - /run/airspy_adsb:/run/airspy_adsb
      ...
```

### Enabling Disk IO and IOPS data

To allow the container access to the Disk IO data, you should map the following volume:

```yaml
    volumes:
      - /proc/diskstats:/proc/diskstats:ro
      ...
```

### Configuring the Core Temperature graphs

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

## Logging

All logs are to the container's stdout and can be viewed with `docker logs -t [-f] container`.

## Getting help

Please feel free to [open an issue on the project's GitHub](https://github.com/sdr-enthusiasts/docker-tar1090/issues).

We also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.

## Using tar1090 with an SDR

| Variable | Description | Controls which `readsb` option | Default |
|----------|-------------|--------------------------------|---------|
| `READSB_GAIN` | Set gain (in dB). Use `autogain` to have the container determine an appropriate gain, more on this below. | `--gain=<db>` | Max gain |
| `READSB_DEVICE_TYPE` | If using an SDR, set this to `rtlsdr`, `modesbeast`, `gnshulc` depending on the model of your SDR. If not using an SDR, leave un-set. | `--device-type=<type>` | Unset |
| `READSB_RTLSDR_DEVICE` | Select device by serial number. | `--device=<serial>` | Unset |
| `READSB_RTLSDR_PPM` | Set oscillator frequency correction in PPM. See section [Estimating PPM](https://github.com/docker-readsb/README.MD#estimating-ppm) below | `--ppm=<correction>` | Unset |
| `READSB_BEAST_SERIAL` | only when type `modesbeast` or `gnshulc` is used: Path to Beast serial device. | `--beast-serial=<path>` | `/dev/ttyUSB0` |

Example (devices: section is mandatory)

```yaml
version: '3.8'

services:

  tar1090:
    image: ghcr.io/sdr-enthusiasts/docker-tar1090:latest
    tty: true
    container_name: tar1090
    hostname: tar1090
    restart: always
    environment:
      - TZ=Australia/Perth
      - LAT=-33.33333
      - LONG=111.11111
      - READSB_DEVICE_TYPE=rtlsdr
      - READSB_GAIN=43.9
      - READSB_RTLSDR_DEVICE=0
    ports:
      - 8078:80
    tmpfs:
      - /run:exec,size=64M
      - /var/log

    devices:
      - /dev/bus/usb:/dev/bus/usb
```

## globe-history or sometimes ironically called destroy-sd-card

See also: <https://github.com/wiedehopf/tar1090#0800-destroy-sd-card>

```yaml
    environment:
    ...
      - READSB_EXTRA_ARGS=--write-json-globe-index --write-globe-history /var/globe_history
    ...
    volumes:
      - /hostpath/to/your/globe_history:/var/globe_history
```

The first part of the mount before the : is the path on the docker host, don't change the 2nd part.
Using this volume gives you persistence for the history / heatmap / range outline

Note that this mode will make T not work as before for displaying all tracks as tracks are only loaded when you click them.
