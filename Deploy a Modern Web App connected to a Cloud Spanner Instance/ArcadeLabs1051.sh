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
echo -e "${CYAN}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo -e "${CYAN}${BOLD_TEXT}              Arcade Labs Solution            ${RESET_FORMAT}"
echo -e "${CYAN}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo



gcloud auth list

gcloud config set project $DEVSHELL_PROJECT_ID

gcloud services enable spanner.googleapis.com artifactregistry.googleapis.com containerregistry.googleapis.com run.googleapis.com

sleep 20


git clone https://github.com/GoogleCloudPlatform/training-data-analyst


cd training-data-analyst/courses/cloud-spanner/omegatrade/backend


cat > .env <<EOF_CP
PROJECTID = $DEVSHELL_PROJECT_ID
INSTANCE = omegatrade-instance
DATABASE = omegatrade-db
JWT_KEY = w54p3Y?4dj%8Xqa2jjVC84narhe5Pk
EXPIRE_IN = 30d
EOF_CP


nvm install node

npm install npm -g
npm install --loglevel=error



npm install npm latest

npm install --loglevel=error

docker build -t gcr.io/$DEVSHELL_PROJECT_ID/omega-trade/backend:v1 -f dockerfile.prod .

gcloud auth configure-docker --quiet


docker push gcr.io/$DEVSHELL_PROJECT_ID/omega-trade/backend:v1

gcloud run deploy omegatrade-backend --platform managed --region $REGION --image gcr.io/$DEVSHELL_PROJECT_ID/omega-trade/backend:v1 --memory 512Mi --allow-unauthenticated


unset SPANNER_EMULATOR_HOST
node seed-data.js


echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}On Completing the Lab !!!${RESET}"


echo
echo -e "${YELLOW}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo -e "${WHITE}${BOLD_TEXT}            Subscribe To Arcade Labs          ${RESET_FORMAT}"
echo -e "${YELLOW}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo