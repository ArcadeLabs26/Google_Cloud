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



export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")


gcloud projects get-iam-policy $(gcloud config get-value project) \
    --format=json > policy.json

echo "${GREEN}${BOLD}Updating IAM Policy...${RESET}"
jq '{ 
  "auditConfigs": [ 
    { 
      "service": "cloudresourcemanager.googleapis.com", 
      "auditLogConfigs": [ 
        { 
          "logType": "ADMIN_READ" 
        } 
      ] 
    } 
  ] 
} + .' policy.json > updated_policy.json


gcloud projects set-iam-policy $(gcloud config get-value project) updated_policy.json


gcloud services enable securitycenter.googleapis.com --project=$DEVSHELL_PROJECT_ID


echo "${YELLOW}${BOLD}Waiting for API to be enabled...${RESET}"
sleep 20


gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:demouser1@gmail.com --role=roles/bigquery.admin


gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:demouser1@gmail.com --role=roles/bigquery.admin


gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/cloudresourcemanager.projectIamAdmin 2>/dev/null


gcloud compute instances create instance-1 \
--zone=$ZONE \
--machine-type=e2-medium \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
--metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD \
--scopes=https://www.googleapis.com/auth/cloud-platform --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230912,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced


gcloud dns --project=$DEVSHELL_PROJECT_ID policies create dns-test-policy --description="quickgcplab" --networks="default" --private-alternative-name-servers="" --no-enable-inbound-forwarding --enable-logging


echo "${YELLOW}${BOLD}Waiting for DNS Policy to take effect...${RESET}"
sleep 30


echo "${MAGENTA}${BOLD}Connecting to Compute Instance...${RESET}"
gcloud compute ssh instance-1 --zone=$ZONE --tunnel-through-iap --project "$DEVSHELL_PROJECT_ID" --quiet --command "gcloud projects get-iam-policy \$(gcloud config get project) && curl etd-malware-trigger.goog"

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress for Task 1 & Task 2? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress for Task 1 & Task 2 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}


check_progress


echo "${BLUE}${BOLD}Deleting Compute Instance...${RESET}"
gcloud compute instances delete instance-1 --zone=$ZONE --quiet

echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}On Completion !!!${RESET}"

echo
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo -e "${YELLOW}${BOLD}         Subscribe To Arcade Labs          ${RESET}"
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo








