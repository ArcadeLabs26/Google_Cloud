#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=$(tput bold)
RESET=$(tput sgr0)


echo
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo -e "${YELLOW}${BOLD}              Arcade Labs Solution            ${RESET}"
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo


read -p "${YELLOW}${BOLD}Enter the ZONE: ${RESET}" ZONE

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress..${RESET}"


# Export variables after collecting input
export ZONE

gcloud compute instances create instance2 --zone=$ZONE --machine-type=e2-medium


cat > arcadelabs.json <<EOF_CP
{
  "displayName": "Uptime Check Policy",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - Check passed",
      "conditionAbsent": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.labels.check_id = \"demogroup-uptime-check-f-UeocjSHdQ\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_FRACTION_TRUE"
          }
        ],
        "duration": "300s",
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {},
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_CP


gcloud alpha monitoring policies create --policy-from-file=arcadelabs.json

    echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}On Completing the Lab !!!${RESET}"


echo
echo -e "${YELLOW}${BOLD}==============================================${RESET}"
echo -e "${WHITE}${BOLD}            Subscribe To Arcade Labs          ${RESET}"
echo -e "${YELLOW}${BOLD}==============================================${RESET}"
echo








