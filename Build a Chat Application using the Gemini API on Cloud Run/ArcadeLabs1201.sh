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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress${RESET}"

PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID
export REGION
export AR_REPO='chat-app-repo'
export SERVICE_NAME='chat-flask-app'



gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com

gsutil cp -R gs://spls/gsp1201/chat-flask-cloudrun .
cd chat-flask-cloudrun || exit


gcloud artifacts repositories create "$AR_REPO" \
  --location="$REGION" \
  --repository-format=Docker 



gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME"


gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME:latest" \
  --allow-unauthenticated \
  --region="$REGION" \
  --platform=managed \
  --project="$PROJECT_ID" \
  --set-env-vars=GCP_PROJECT="$PROJECT_ID",GCP_REGION="$REGION"

echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Lab Completed !!!${RESET}"

echo
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo -e "${YELLOW}${BOLD}         Subscribe To Arcade Labs          ${RESET}"
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo








