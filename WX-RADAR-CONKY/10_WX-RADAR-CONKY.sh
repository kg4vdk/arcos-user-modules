#!/bin/bash

#############################
# WX-RADAR-CONKY QRV MODULE #
#############################
MODULE="WX-RADAR-CONKY"

# STATION INFO
MYCALL=$(head -n 1 $HOME/.station-info)
MYNAME=$(head -n 2 $HOME/.station-info | tail -n 1)
MYCITY=$(head -n 3 $HOME/.station-info | tail -n 1)
MYST=$(head -n 4 $HOME/.station-info | tail -n 1)
MYQTH="${MYCITY}, ${MYST}"
MYLOC=$(head -n 5 $HOME/.station-info | tail -n 1)

# PATHS
ARCOS_DATA=/arcHIVE
MODULE_DIR=$ARCOS_DATA/QRV/$MYCALL/arcos-linux-modules/USER/$MODULE
LOGFILE=$MODULE_DIR/$MODULE.log
SAVE_DIR=$ARCOS_DATA/QRV/$MYCALL/SAVED/$MODULE
########################

### MODULE COMMANDS FUNCTION ###
module_commands () {

################### USER DEFINED VARIABLES ###################

# Define NWS Radar Station (e.g. KOHX), or leave empty for national map
# https://www.roc.noaa.gov/branches/program-branch/site-id-database/site-id-location-maps.php
NWS_STATION="KOHX"

# Sizes available: large, medium, small, tiny, tiny-integrated
SIZE="tiny-integrated"

##############################################################

# If NWS Station is empty use the national map
if [ "${NWS_STATION}" == "" ]; then
	NWS_STATION="CONUS"
fi

# Set image sizes
case $SIZE in

  large)
    if [ "${NWS_STATION}" == "CONUS" ]; then
		XXX="600"
		YYY="392"
	else
		XXX="600"
		YYY="550"
	fi
    ;;

  medium)
    if [ "${NWS_STATION}" == "CONUS" ]; then
		XXX="480"
		YYY="314"
	else
		XXX="480"
		YYY="440"
	fi
    ;;

  small)
    if [ "${NWS_STATION}" == "CONUS" ]; then
		XXX="420"
		YYY="274"
	else
		XXX="420"
		YYY="385"
	fi
    ;;
    
  tiny)
    if [ "${NWS_STATION}" == "CONUS" ]; then
		XXX="220"
		YYY="144"
	else
		XXX="220"
		YYY="202"
	fi
    ;;
    
  tiny-integrated)
    INTEGRATED="true"
    if [ "${NWS_STATION}" == "CONUS" ]; then
		XXX="220"
		YYY="144"
	else
		XXX="220"
		YYY="202"
	fi
    ;;

  *)
    INTEGRATED="true"
    if [ "${NWS_STATION}" == "CONUS" ]; then
		XXX="220"
		YYY="144"
	else
		XXX="220"
		YYY="202"
	fi
    ;;
esac


# Add to cron downloading image every minute
cat << EOF | sudo tee --append /etc/crontab
*/2 * * * * user /usr/bin/wget -O /tmp/radar.gif https://radar.weather.gov/ridge/standard/${NWS_STATION}_0.gif || rm /tmp/radar.gif
EOF

# Restart cron
sudo systemctl restart cron.service

# Download first image if network is reachable
if ping -c 5 radar.weather.gov; then
	wget -O /tmp/radar.gif https://radar.weather.gov/ridge/standard/${NWS_STATION}_0.gif
fi

# Kill any already running WX conky
pkill -f "wx-conkyrc"

# # Create config and place in /tmp
cp ${MODULE_DIR}/config/wx-conkyrc /tmp/wx-conkyrc
sed -i "s/XXX/${XXX}/" /tmp/wx-conkyrc
sed -i "s/YYY/${YYY}/" /tmp/wx-conkyrc
if [ "${INTEGRATED}" == "true" ]; then
	sed -i "s/alignment = 'top_right'/alignment = 'bottom_right'/" /tmp/wx-conkyrc
	sed -i "s/gap_y = 5/gap_y = 425/" /tmp/wx-conkyrc
fi

# Start WX conky
conky -c /tmp/wx-conkyrc -qd

} # END OF MODULE COMMANDS FUNCTION

# Execute the module commands, and notify the user upon failure
module_commands > $LOGFILE 2>&1 || notify-send --icon=error "$MODULE" "$MODULE module failed!"

