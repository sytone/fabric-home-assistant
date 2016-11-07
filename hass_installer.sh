#!/usr/bin/env bash
# Home Assistant Installer Kickstarter
# Copyright (C) 2016 Jonathan Baginski - All Rights Reserved
# Permission to copy and modify is granted under the MIT License
# Modified to be more generic by Jon Bullen
# Last revised 09/03/2016


#Set Script Name variable
SCRIPT=`basename ${BASH_SOURCE[0]}`

#Initialize variables to default values.
VIRTUAL_ENV='virtual=no'   
ZWAVE_ENABLED='openzwave=no'
MOS_ENABLED='mosquitto=no'
FAB_USER='pi'
FAB_PASSWORD='raspberry'
MOS_USER='pi'
MOS_PASSWORD='raspberry' 
GIT_REPO='home-assistant'
GIST_USERNAME=''

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
  echo "${REV}-r${NORM}  --Git Repo. Default is ${BOLD}sytone${NORM}."
  echo "${REV}-l${NORM}  --Git Username to upload the installation log to. Default is none. (Beta)"
  echo -e "${REV}-h${NORM}  --Displays this help message. No further functions are performed."\\n
  echo -e "Example: ${BOLD}$SCRIPT -vzm${NORM}"\\n
  exit 1
}

echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1mHome Assistant Installer\e[0m "
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"


while getopts ":vzmu:p:s:a:r:l:" opt; do
  case $opt in
    v)
      echo "  - Python virtual environment being used." >&2
      VIRTUAL_ENV='virtual=yes'
      ;;
    z)
      echo "  - Installing and Enabling Open ZWave" >&2
      ZWAVE_ENABLED='openzwave=yes'
      ;;
    m)
      echo "  - Installing and Enabling Mosquitto" >&2
      MOS_ENABLED='mosquitto=yes'
      ;;
    u)
      echo "  - Fabric username specified as: $OPTARG" >&2
      FAB_USER=$OPTARG
      ;;
    p)
      echo "  - Fabric Password specified as: $OPTARG" >&2
      FAB_PASSWORD=$OPTARG
      ;;
    s)
      echo "  - Mosquitto username specified as: $OPTARG" >&2
      MOS_USER=$OPTARG
      ;;
    a)
      echo "  - Mosquitto Password specified as: $OPTARG" >&2
      MOS_PASSWORD=$OPTARG
      ;;
    r)
      echo "  - Git repo to use is: $OPTARG" >&2
      GIT_REPO=$OPTARG
      ;;
    l)
      echo "  - Uploading logs to $OPTARG on gist. (Beta)" >&2
      GIST_USERNAME=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      HELP
      ;;
  esac
done


 
## Run pre-install apt package dependency checks ##
# Common packages
#
ME=$(whoami)
echo -e "\n \e[39;49;1mCurrent User: \e[90m$ME\e[0m "
if [ "root" == "$ME" ]; then
  echo -e " \e[39;49;1mAborting! Do not install using root account! \e[0m "
  echo -e " \e[39;49;1mMake a user with a command like this and log in with that account:\e[0m"
  echo -e "    sudo adduser <username>"
  echo -e "    sudo adduser <username> sudo"
  exit
fi
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1mUpdating packages and validating packages\e[0m "
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"

sudo apt-get -qq update

PKG_PYDEV=$(dpkg-query -W --showformat='${Status}\n' python3-dev|grep "install ok installed")
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo "   - Checking for python3-dev: $PKG_PYDEV"
if [ "" == "$PKG_PYDEV" ]; then
  echo "   ! No python3-dev. Setting up python3-dev."
  sudo apt-get -qq --force-yes --yes install python3-dev
fi
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"

PKG_PYPIP=$(dpkg-query -W --showformat='${Status}\n' python3-pip|grep "install ok installed")
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo "   - Checking for python3-pip: $PKG_PYPIP"
if [ "" == "$PKG_PYPIP" ]; then
  echo "   ! No python3-pip. Setting up python3-pip."
  sudo apt-get -qq --force-yes --yes install python3-pip
fi
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"

PKG_GIT=$(dpkg-query -W --showformat='${Status}\n' git|grep "install ok installed")
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo "   - Checking for git: $PKG_GIT"
if [ "" == "$PKG_GIT" ]; then
  echo "   ! No git. Setting up git."
  sudo apt-get -qq --force-yes --yes install git
fi
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"

PKG_APTITUDE=$(dpkg-query -W --showformat='${Status}\n' aptitude|grep "install ok installed")
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo "   - Checking for aptitude: $PKG_APTITUDE"
if [ "" == "$PKG_APTITUDE" ]; then
  echo "   ! No aptitude. Setting up aptitude."
  sudo apt-get -qq --force-yes --yes install aptitude
fi
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"

echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1mInstalling Python Fabric 3\e[0m "
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
sudo /usr/bin/pip3 install fabric3

echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1mPulling the addtional install scripts\e[0m "
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1mGIT Repo: \e[90mhttps://github.com/$GIT_REPO/fabric-home-assistant.git\e[0m \n"
rm -fr ./fabric-home-assistant/
git clone https://github.com/$GIT_REPO/fabric-home-assistant.git
cd /home/$ME/fabric-home-assistant

echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1mRunning fabric deployment\e[0m "
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1m - VIRTUAL_ENV   :\e[90m $VIRTUAL_ENV \e[0m "
echo -e " \e[39;49;1m - ZWAVE_ENABLED :\e[90m $ZWAVE_ENABLED \e[0m "
echo -e " \e[39;49;1m - MOS_ENABLED   :\e[90m $MOS_ENABLED \e[0m "
echo -e " \e[39;49;1m - FAB_USER      :\e[90m $FAB_USER \e[0m "
echo -e " \e[39;49;1m - FAB_PASSWORD  :\e[90m $FAB_PASSWORD \e[0m "
echo -e " \e[39;49;1m - MOS_USER      :\e[90m $MOS_USER \e[0m "
echo -e " \e[39;49;1m - MOS_PASSWORD  :\e[90m $MOS_PASSWORD \e[0m "
echo -e " \e[39;49;1m - GIT_REPO      :\e[90m $GIT_REPO \e[0m "
echo -e " \e[39;49;1m - GIST_USERNAME :\e[90m $GIST_USERNAME \e[0m "

echo -e " FAB Command:"
echo -e "  fab deploy:$VIRTUAL_ENV,$ZWAVE_ENABLED,$MOS_ENABLED,username=$FAB_USER,password=$FAB_PASSWORD,mosusername=$MOS_USER,mospassword=$MOS_PASSWORD -H localhost"

FNAME=installation_report.txt

fab deploy:$VIRTUAL_ENV,$ZWAVE_ENABLED,$MOS_ENABLED,username=$FAB_USER,password=$FAB_PASSWORD,mosusername=$MOS_USER,mospassword=$MOS_PASSWORD -H localhost 2>&1 | tee $FNAME

#CONTENT=$(sed -e 's/\r//' -e's/\t/\\t/g' -e 's/"/\\"/g' "${FNAME}" | awk '{ printf($0 "\\n") }')
#read -r -d '' DESC <<EOF
# {
#  "description": "some description",
#  "public": true,
#  "files": {
#    "${FNAME}": {
#      "content": "${CONTENT}"
#    }
#  }
#}
#EOF

#curl -u "${GIST_USERNAME}" -X POST -d "${DESC}" "https://api.github.com/gists"

exit

