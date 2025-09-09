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



read -p "${YELLOW}${BOLD}Enter the location: ${RESET}" LOCATION
export LOCATION=$LOCATION
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects list --filter=projectId:$PROJECT_ID \
  --format="value(projectNumber)")
export DATASET_ID=dataset1
export FHIR_STORE_ID=fhirstore1
export TOPIC=fhir-topic
export HL7_STORE_ID=hl7v2store1 # Note: This variable isn't used later, maybe remove if not needed?


gcloud services enable healthcare.googleapis.com --project=$PROJECT_ID
sleep 10


gcloud pubsub topics create $TOPIC --project=$PROJECT_ID


bq --location=$LOCATION mk --dataset --description "HCAPI dataset" $PROJECT_ID:$DATASET_ID


bq --location=$LOCATION mk --dataset --description "HCAPI dataset de-id" $PROJECT_ID:de_id


gcloud healthcare datasets create $DATASET_ID \
  --location=$LOCATION \
  --project=$PROJECT_ID


sleep 15


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"



gcloud healthcare fhir-stores create $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --version=R4 \
  --project=$PROJECT_ID


gcloud healthcare fhir-stores update $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --pubsub-topic=projects/$PROJECT_ID/topics/$TOPIC \
  --project=$PROJECT_ID


gcloud healthcare fhir-stores create de_id \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --version=R4 \
  --project=$PROJECT_ID


gcloud healthcare fhir-stores import gcs $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --gcs-uri=gs://spls/gsp457/fhir_devdays_gcp/fhir1/* \
  --content-structure=BUNDLE_PRETTY \
  --project=$PROJECT_ID


gcloud healthcare fhir-stores export bq $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --bq-dataset=bq://$PROJECT_ID.$DATASET_ID \
  --schema-type=analytics \
  --project=$PROJECT_ID





echo "${GREEN}${BOLD}OPEN THIS LINK: ${BLUE}${BOLD}https://console.cloud.google.com/healthcare/browser?project=${PROJECT_ID} ${RESET}" 

echo "${YELLOW}${BOLD}Have you completed the video steps? (y/n): ${RESET}"
read -r answer
if [[ $answer == "y" || $answer == "Y" ]]; then
    echo "${YELLOW}${BOLD}Great! Proceeding with the next steps...${RESET}"
else
    echo "${YELLOW}${BOLD}Please complete the video steps before proceeding.${RESET}"
fi
echo


echo "${YELLOW}Waiting (30s) for managing resources (if any)...${RESET}" 
sleep 30


gcloud healthcare fhir-stores export bq de_id \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --bq-dataset=bq://$PROJECT_ID.de_id \
  --schema-type=analytics \
  --project=$PROJECT_ID


echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Lab Completed !!!${RESET}"

echo
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo -e "${YELLOW}${BOLD}         Subscribe To Arcade Labs          ${RESET}"
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo








