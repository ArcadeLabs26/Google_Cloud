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


echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress..${RESET}"


# Prompt user for region input
read -p "${BLUE}${BOLD}Enter Region: ${RESET}" REGION
export REGION

# Enable Dataplex API
gcloud services enable dataplex.googleapis.com

# Create Dataplex Lake
gcloud alpha dataplex lakes create sensors \
 --location=$REGION \
 --labels=k1=v1,k2=v2,k3=v3 

# Create Dataplex Zone
gcloud alpha dataplex zones create temperature-raw-data \
            --location=$REGION --lake=sensors \
            --resource-location-type=SINGLE_REGION --type=RAW

# Create Storage Bucket
gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID

# Create Dataplex Asset
gcloud dataplex assets create measurements --location=$REGION \
            --lake=sensors --zone=temperature-raw-data \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID

# Cleanup: Delete Dataplex Asset
gcloud dataplex assets delete measurements --zone=temperature-raw-data --lake=sensors --location=$REGION --quiet

# Cleanup: Delete Dataplex Zone
gcloud dataplex zones delete temperature-raw-data --lake=sensors --location=$REGION --quiet

# Cleanup: Delete Dataplex Lake
gcloud dataplex lakes delete sensors --location=$REGION --quiet


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    rm -- "$SCRIPT_NAME"
fi


# Completion message
    echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}On Completing the Lab !!!${RESET}"


echo
echo -e "${YELLOW}${BOLD}==============================================${RESET}"
echo -e "${WHITE}${BOLD}            Subscribe To Arcade Labs          ${RESET}"
echo -e "${YELLOW}${BOLD}==============================================${RESET}"
echo








