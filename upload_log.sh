#!/usr/bin/env bash

#Set Script Name variable
SCRIPT=`basename ${BASH_SOURCE[0]}`

#Initialize variables to default values.
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
  echo "${REV}-l${NORM}  --Git Username to upload the installation log to. Default is none."
  echo -e "${REV}-?${NORM}  --Displays this help message. No further functions are performed."\\n
  echo -e "Example: ${BOLD}$SCRIPT -l fredsmith${NORM}"\\n
  exit 1
}

echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"
echo -e " \e[39;49;1mHome Assistant Log Uploader \e[0m "
echo -e " \e[38;5;93m──────────────────────────────────────────────────\e[0m"


while getopts ":hl:" opt; do
  case $opt in
    l)
      echo "  - Uploading logs to $OPTARG on gist." >&2
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

INPUT_FILE=installation_report.txt
OUTPUT_FILE=installation_report.clean.txt
tr -cd '\11\12\40-\176' < $INPUT_FILE > $OUTPUT_FILE
# 1. Somehow sanitize the file content
#    Remove \r (from Windows end-of-lines),
#    Replace tabs by \t
#    Replace " by \"
#    Replace EOL by \n
CONTENT=$(sed -e 's/\r//' -e's/\t/\\t/g' -e 's/"/\\"/g' "${OUTPUT_FILE}" | awk '{ printf($0 "\\n") }')
read -r -d '' DESC <<EOF
{
  "description": "some description",
  "public": true,
  "files": {
    "${OUTPUT_FILE}": {
      "content": "${CONTENT}"
    }
  }
}
EOF
curl -u "${GIST_USERNAME}" -X POST -d "${DESC}" "https://api.github.com/gists"
exit

