#!/usr/bin/env bash
# Home Assistant Installer Kickstarter
# Copyright (C) 2016 Jonathan Baginski - All Rights Reserved
# Permission to copy and modify is granted under the MIT License
# Last revised 5/15/2016

#Set Script Name variable
SCRIPT=`basename ${BASH_SOURCE[0]}`

#Initialize variables to default values.
VIRTUAL_ENV='virtual=no'
ZWAVE_ENABLED='openzwave=no'
MOS_ENABLED='mosquitto=no'
FAB_USER=U
FAB_PASSWORD=P
MOS_USER=M
MOS_PASSWORD=A

#Set fonts for Help.
NORM=`tput sgr0`
BOLD=`tput bold`
REV=`tput smso`

#Help function
function HELP {
  echo -e \\n"Help documentation for ${BOLD}${SCRIPT}.${NORM}"\\n
  echo -e "${REV}Basic usage:${NORM} ${BOLD}$SCRIPT ${NORM}"\\n
  echo "Command line switches are optional. The following switches are recognized."
  echo "${REV}-v${NORM}  --Enables the use of Python Virtual Environments."
  echo "${REV}-z${NORM}  --Install Open ZWave."
  echo "${REV}-m${NORM}  --Install Mosquitto."
  echo "${REV}-u${NORM}  --Fabric username. Default is ${BOLD}pi${NORM}."
  echo "${REV}-p${NORM}  --Fabric Password. Default is ${BOLD}raspberry${NORM}."
  echo "${REV}-s${NORM}  --Mosquitto username. Default is ${BOLD}pi${NORM}."
  echo "${REV}-a${NORM}  --Mosquitto Password. Default is ${BOLD}raspberry${NORM}."
  echo -e "${REV}-h${NORM}  --Displays this help message. No further functions are performed."\\n
  echo -e "Example: ${BOLD}$SCRIPT -vzm${NORM}"\\n
  exit 1
}

while getopts ":vzmu:p:s:a:" opt; do
  case $opt in
    v)
      echo "Python virtual environment being used." >&2
      VIRTUAL_ENV='virtual=yes'
      ;;
    v)
      echo "Installing and Enabling Open ZWave" >&2
      ZWAVE_ENABLED='openzwave=yes'
      ;;
    m)
      echo "Installing and Enabling Mosquitto" >&2
      MOS_ENABLED='mosquitto=yes'
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done


# fab new_user:myusername,admin=yes
fab $VIRTUAL_ENV -H localhost 2>&1 | tee installation_report.txt

# Options:
# -n No Python virtual environment
# -z Install ZWave components
#

usage() { echo "Usage: $0 [-n] [-z]" 1>&2; exit 1; }


## Run pre-install apt package dependency checks ##

# Common packages
#
me=$(whoami)

sudo apt-get update

PKG_PYDEV=$(dpkg-query -W --showformat='${Status}\n' python3-dev|grep "install ok installed")
echo Checking for python3-dev: $PKG_PYDEV
if [ "" == "$PKG_PYDEV" ]; then
  echo "No python3-dev. Setting up python3-dev."
  sudo apt-get --force-yes --yes install python3-dev
fi

PKG_PYPIP=$(dpkg-query -W --showformat='${Status}\n' python3-pip|grep "install ok installed")
echo Checking for python3-pip: $PKG_PYPIP
if [ "" == "$PKG_PYPIP" ]; then
  echo "No python3-pip. Setting up python3-pip."
  sudo apt-get --force-yes --yes install python3-pip
fi

PKG_GIT=$(dpkg-query -W --showformat='${Status}\n' git|grep "install ok installed")
echo Checking for git: $PKG_GIT
if [ "" == "$PKG_GIT" ]; then
  echo "No git. Setting up git."
  sudo apt-get --force-yes --yes install git
fi

PKG_APTITUDE=$(dpkg-query -W --showformat='${Status}\n' aptitude|grep "install ok installed")
echo Checking for aptitude: $PKG_APTITUDE
if [ "" == "$PKG_APTITUDE" ]; then
  echo "No aptitude. Setting up aptitude."
  sudo apt-get --force-yes --yes install aptitude
fi

sudo /usr/bin/pip install fabric

git clone https://github.com/sytone/fabric-home-assistant.git
cd /home/$me/fabric-home-assistant



deploy -H localhost 2>&1 | tee installation_report.txt )
exit

