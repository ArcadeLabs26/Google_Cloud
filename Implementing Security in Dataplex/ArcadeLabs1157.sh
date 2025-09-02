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


gcloud auth list

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud services enable dataplex.googleapis.com datacatalog.googleapis.com

gcloud dataplex lakes create customer-info-lake --location=$REGION --display-name="Techcps Info Lake"

gcloud dataplex zones create customer-raw-zone --location=$REGION --display-name="Techcps Raw Zone" --lake=customer-info-lake --type=RAW --resource-location-type=SINGLE_REGION

gcloud dataplex assets create customer-online-sessions \
  --location=$REGION \
  --display-name="Techcps Online Sessions" \
  --lake=customer-info-lake \
  --zone=customer-raw-zone \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$PROJECT_ID/buckets/$PROJECT_ID-bucket


echo
echo -e "\033[1;33mClick Grant access\033[0m \033[1;34mhttps://console.cloud.google.com/dataplex/secure?inv=1&invt=AbyNQg&project=$PROJECT_ID\033[0m"
echo



echo
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo -e "${YELLOW}${BOLD}         Subscribe To Arcade Labs          ${RESET}"
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo








