#!/bin/bash
# __     ______ ___  ____  _____ 
# \ \   / / ___/ _ \|  _ \| ____|
#  \ \ / / |  | | | | |_) |  _|  
#   \ V /| |__| |_| |  _ <| |___ 
#    \_/  \____\___/|_| \_\_____| 3.1
#           Standalone 300 Setup.
# 
#
###################################
###### GRAPH PLOTTING SCRIPT ######
###################################
# Written by Frix_x#0161 #
# @version: 1.5

# CHANGELOG:
#   v1.5: fixed klipper unnexpected fail at the end of the execution, even if graphs were correctly generated (unicode decode error fixed)
#   v1.4: added the ~/klipper dir parameter to the call of graph_vibrations.py for a better user handling (in case user is not "pi")
#   v1.3: some documentation improvement regarding the line endings that needs to be LF for this file
#   v1.2: added the movement name to be transfered to the Python script in vibration calibration (to print it on the result graphs)
#   v1.1: multiple fixes and tweaks (mainly to avoid having empty files read by the python scripts after the mv command)
#   v1.0: first version of the script based on a Zellneralex script

# Installation:
#   1. Copy this file somewhere in your config folder and edit the parameters below if needed
#      Note: If using Windows to do the copy/paste, be careful with the line endings for this file: LF (or \n) is mandatory !!! No \r should be
#            present in the file as it could lead to some errors like "\r : unknown command" when running the script. If you're not confident
#            regarding your text editor behavior, the best way is to directly download the file on the pi by using for example wget:
#            type 'wget -P ~/printer_data/config/scripts https://raw.githubusercontent.com/Frix-x/klipper-voron-V2/main/scripts/plot_graphs.sh'
#   2. Make it executable using SSH: type 'chmod +x ~/printer_data/config/scripts/plot_graphs.sh' (adjust the path if needed).
#   3. Be sure to have the gcode_shell_command.py Klipper extension installed (easiest way to install it is to use KIAUH in the Advanced section)
#   4. Create a gcode_shell_command to be able to start it from a macro (see my shell_commands.cfg file)

# Usage:
#   This script was designed to be used with gcode_shell_commands. Use it to call it.
#   Parameters availables:
#      SHAPER      - To generate input shaper diagrams after calling the Klipper TEST_RESONANCES AXIS=X/Y
#      BELTS       - To generate belts diagrams after calling the Klipper TEST_RESONANCES AXIS=1,(-)1 OUTPUT=raw_data
#      VIBRATIONS  - To generate vibration diagram after calling the custom (Frix_x#0161) VIBRATIONS_CALIBRATION macro


#################################################################################################################
RESULTS_FOLDER=~/printer_data/config/adxl_results # Path to the folder where storing the results files
SCRIPTS_FOLDER=~/printer_data/config/scripts # Path to the folder where the graph_vibrations.py is located
KLIPPER_FOLDER=~/klipper # Path of the klipper main folder
#################################################################################################################


#####################################################################
################ !!! DO NOT EDIT BELOW THIS LINE !!! ################
#####################################################################

export LC_ALL=C

function plot_shaper_graph {
  local generator filename newfilename date axis
  date_ext="$(date +'%Y-%m-%d-%H%M%S')"
  generator="${KLIPPER_FOLDER}/scripts/calibrate_shaper.py"
  
  while read filename; do
    newfilename="$(echo ${filename} | sed -e "s/\\/tmp\///")"
    axis="$(basename "${newfilename}" | cut -d '_' -f2)"
    "${generator}" "${filename}" -o "${isf}"/inputshaper/resonances_"${axis}"_"${date_ext}".png
    rm "${filename}"
  done <<< "$(find /tmp -type f -name "resonances_*.csv" 2>&1 | grep -v "Permission")"
}


function plot_belts_graph {
  local date_ext generator filename belt
  date_ext="$(date +'%Y-%m-%d-%H%M%S')"
  generator="${KLIPPER_FOLDER}/scripts/graph_accelerometer.py"
  sync && sleep 6
  "${generator}" -c /tmp/raw_data_axis*_belt-tension-*.csv -o "${isf}"/belts/belt-tension-"${date_ext}".png
  sync && sleep 2
  rm /tmp/raw_data_axis*_belt-tension-*.csv
}


function plot_vibr_graph {
  local date_ext generator filename newfilename
  date_ext="$(date +'%Y-%m-%d-%H%M%S')"
  generator="${SCRIPTS_FOLDER}/graph_vibrations.py"
  sync && sleep 6
  "${generator}" /tmp/adxl345-*.csv -o "${isf}/vibrations/vibrations-${1}_${date_ext}".png -a "${1}" -k "${KLIPPER_FOLDER}"
  sync && sleep 2
  echo "rm lol"
  rm /tmp/adxl345-*.csv
}


#############################
### MAIN ####################
#############################

if [ ! -d "${RESULTS_FOLDER}/inputshaper" ]; then
  mkdir -p "${RESULTS_FOLDER}/inputshaper"
fi
if [ ! -d "${RESULTS_FOLDER}/belts" ]; then
  mkdir -p "${RESULTS_FOLDER}/belts"
fi
if [ ! -d "${RESULTS_FOLDER}/vibrations" ]; then
  mkdir -p "${RESULTS_FOLDER}/vibrations"
fi

isf="${RESULTS_FOLDER//\~/${HOME}}"

case ${1} in
  SHAPER|shaper)
    plot_shaper_graph
  ;;
  BELTS|belts)
    plot_belts_graph
  ;;
  VIBRATIONS|vibrations)
    plot_vibr_graph ${2}
  ;;
  *)
  echo -e "\nUsage:"
  echo -e "\t${0} SHAPER, BELTS or VIBRATIONS"
  echo -e "\t\tSHAPER\tGenerate input shaper diagram"
  echo -e "\t\tBELT\tGenerate belt tension diagram"
  echo -e "\t\tVIBRATIONS axis-name\tGenerate vibration response diagram\n"
  exit 1
esac


echo "Graphs created. You will find the results in ${isf}"
