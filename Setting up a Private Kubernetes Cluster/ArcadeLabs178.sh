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
echo -e "${CYAN}${BOLD_TEXT}================================================${RESET_FORMAT}"
echo -e "${YELLOW}${BOLD_TEXT}              Arcade Labs Solution            ${RESET_FORMAT}"
echo -e "${CYAN}${BOLD_TEXT}================================================${RESET_FORMAT}"
echo

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress${RESET}"

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"

gcloud beta container clusters create private-cluster --enable-private-nodes --master-ipv4-cidr 172.16.0.16/28 --enable-ip-alias --create-subnetwork ""

gcloud compute instances create source-instance --zone=$ZONE --scopes 'https://www.googleapis.com/auth/cloud-platform'

NAT_IAP=$(gcloud compute instances describe source-instance --zone=$ZONE | grep natIP | awk '{print $2}')

gcloud container clusters update private-cluster --enable-master-authorized-networks --master-authorized-networks $NAT_IAP/32

gcloud container clusters delete private-cluster --zone=$ZONE --quiet

gcloud compute networks subnets create my-subnet --network default --range 10.0.4.0/22 --enable-private-ip-google-access --region=$REGION --secondary-range my-svc-range=10.0.32.0/20,my-pod-range=10.4.0.0/14
    
gcloud beta container clusters create private-cluster2 --enable-private-nodes --enable-ip-alias --master-ipv4-cidr 172.16.0.32/28 --subnetwork my-subnet --services-secondary-range-name my-svc-range --cluster-secondary-range-name my-pod-range --zone=$ZONE

NAT_IAP_CP=$(gcloud compute instances describe source-instance --zone=$ZONE | grep natIP | awk '{print $2}')

gcloud container clusters update private-cluster2 --enable-master-authorized-networks --zone=$ZONE --master-authorized-networks $NAT_IAP_CP/32


    echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}On Completing the Lab !!!${RESET}"


echo
echo -e "${YELLOW}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo -e "${WHITE}${BOLD_TEXT}            Subscribe To Arcade Labs          ${RESET_FORMAT}"
echo -e "${YELLOW}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo