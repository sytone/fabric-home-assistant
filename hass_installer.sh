#!/usr/bin/env bash
# Home Assistant Installer Kickstarter
# Copyright (C) 2016 Jonathan Baginski - All Rights Reserved
# Permission to copy and modify is granted under the MIT License
# Last revised 5/15/2016

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

PKG_PYDEV=$(dpkg-query -W --showformat='${Status}\n' python-dev|grep "install ok installed")
echo Checking for python-dev: $PKG_PYDEV
if [ "" == "$PKG_PYDEV" ]; then
  echo "No python-dev. Setting up python-dev."
  sudo apt-get --force-yes --yes install python-dev
fi

PKG_PYPIP=$(dpkg-query -W --showformat='${Status}\n' python-pip|grep "install ok installed")
echo Checking for python-pip: $PKG_PYPIP
if [ "" == "$PKG_PYPIP" ]; then
  echo "No python-pip. Setting up python-pip."
  sudo apt-get --force-yes --yes install python-pip
fi

PKG_GIT=$(dpkg-query -W --showformat='${Status}\n' git|grep "install ok installed")
echo Checking for python-pip: $PKG_GIT
if [ "" == "$PKG_GIT" ]; then
  echo "No git. Setting up git."
  sudo apt-get --force-yes --yes install git
fi

sudo /usr/bin/pip install fabric

git clone https://github.com/home-assistant/fabric-home-assistant.git
cd /home/$me/fabric-home-assistant

while getopts ":nz" opt; do
  case $opt in
    n)
      echo "No Python virtual environment being used." >&2

      fab deploy_novenv -H localhost 2>&1 | tee installation_report.txt
    exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

deploy -H localhost 2>&1 | tee installation_report.txt )
exit

