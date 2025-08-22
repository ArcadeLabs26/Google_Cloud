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
echo -e "${YELLOW}${BOLD}             Arcade Labs Solution             ${RESET}"
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress${RESET}"



gcloud auth list
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"
gsutil -m cp -r gs://spls/gsp233/* .
cd tf-gke-k8s-service-lb
terraform init
terraform apply -var="region=$REGION" -var="location=$ZONE" --auto-approve



echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Lab Completed !!!${RESET}"


echo
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo -e "${YELLOW}${BOLD}           Subscribe To Arcade Labs           ${RESET}"
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo