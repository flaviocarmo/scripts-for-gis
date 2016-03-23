#!/bin/bash
#
# ***************************************************************************
# Name                 : long_lat_gps.sh
# Description          : Print "image;dop;total_sat;datetime;long;lat;alt"
#
# Arguments: 
# $1: Image
#
# Dependencies         : gdal 1.10.1 (gdalinfo)
#
# ***************************************************************************
# begin                : 2016-03-22 (yyyy-mm-dd)
# copyright            : (C) 2016 by Luiz Motta
# email                : motta dot luiz at gmail.com
# ***************************************************************************
#
# Revisions
#
# 2016-03-23:
# - Add time, datetime, altitude
#
# ***************************************************************************
#
# Example:
#   long_lat_gps.sh P1030986.JPG
#
# ***************************************************************************
# *                                                                         *
# *   This program is free software; you can redistribute it and/or modify  *
# *   it under the terms of the GNU General Public License as published by  *
# *   the Free Software Foundation; either version 2 of the License, or     *
# *   (at your option) any later version.                                   *
# *                                                                         *
# ***************************************************************************
#
#
calc_dd(){
  local sd=$1
  local d=$(echo $in_calc_dd | cut -d' ' -f1 | sed 's/(//g;s/)//g')
  local m=$(echo $in_calc_dd | cut -d' ' -f2 | sed 's/(//g;s/)//g')
  local s=$(echo $in_calc_dd | cut -d' ' -f3 | sed 's/(//g;s/)//g')
  dd=$(echo "scale=10;("$d"+("$m"/60)+("$s"/3600))*"$sd | bc)
}
#
msg_error(){
  local name_script=$(basename $0)
  echo "Usage: $name_script <image>" >&2
  echo "<image> is the image" >&2
  exit 1
}
#
totalargs=1
#
if [ $# -ne $totalargs ] ; then
  msg_error
  exit 1
fi
#
in_img=$1
#
if [ ! -f "$in_img" ] ; then
  echo "The file '$in_img' not exist" >&2
  exit 1
fi
#
exif_info=$(mktemp)
gdalinfo $in_img | grep EXIF_ > $exif_info
value=$(cat $exif_info)
if [ -z "$value" ]; then #Test zero-length
  echo "Image: "$in_img" don't have EXIF tags" 
  exit 1
fi
#
value=$(cat $exif_info | grep EXIF_GPS)
if [ -z "$value" ]; then
  echo "Image: "$in_img" don't have EXIF_GPS tags" 
  exit 1
fi
#
lat=$(cat $exif_info | grep EXIF_GPSLatitude= | cut -d '=' -f2)
slat=$(cat $exif_info | grep EXIF_GPSLatitudeRef= | cut -d '=' -f2)
slat=$(if [ $slat == 'S' ]; then echo '-1'; else echo '1'; fi)
in_calc_dd=$lat
calc_dd $slat
lat=$dd
#
long=$(cat $exif_info | grep EXIF_GPSLongitude= | cut -d '=' -f2)
slong=$(cat $exif_info | grep EXIF_GPSLongitudeRef= | cut -d '=' -f2)
slong=$(if [ $slong == 'W' ]; then echo '-1'; else echo '1'; fi)
in_calc_dd=$long
calc_dd $slong
long=$dd
#
alt=$(cat $exif_info | grep EXIF_GPSAltitude= | cut -d '=' -f2)
if [ -z "$alt" ]; then
  alt="None"
else
  alt=$(echo $alt | sed 's/(//g;s/)//g')
fi
#
gpsDOP=$(cat $exif_info | grep EXIF_GPSDOP= | cut -d '=' -f2 | sed 's/(//g;s/)//g')
if [ -z "$gpsDOP" ]; then
  gpsDOP="None"
fi
gpsSatellites=$(cat $exif_info | grep EXIF_GPSSatellites= | cut -d '=' -f2)
if [ -z "$gpsSatellites" ]; then
  gpsSatellites="None"
fi
datetime=$(cat $exif_info | grep EXIF_DateTime= | cut -d '=' -f2)
#
rm $exif_info
#
# header: echo "image;dop;total_sat;datetime;long;lat;alt" > file.csv
echo $in_img";"$gpsDOP";"$gpsSatellites";"$datetime";"$long";"$lat";"$alt
