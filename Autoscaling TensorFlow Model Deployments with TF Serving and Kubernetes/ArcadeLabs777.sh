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

BOLD=`tput bold`
RESET=`tput sgr0`


echo
echo -e "${CYAN}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo -e "${YELLOW}${BOLD_TEXT}             Arcade Labs Solution           ${RESET_FORMAT}"
echo -e "${CYAN}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo


echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress${RESET}"




gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"

gcloud config set compute/region "$REGION"

cd
SRC_REPO=https://github.com/GoogleCloudPlatform/mlops-on-gcp
kpt pkg get $SRC_REPO/workshops/mlep-qwiklabs/tfserving-gke-autoscaling tfserving-gke
cd tfserving-gke


CLUSTER_NAME=cluster-1

gcloud beta container clusters create $CLUSTER_NAME \
  --cluster-version=latest \
  --machine-type=e2-standard-4 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3 \
  --num-nodes=1 


gcloud container clusters get-credentials $CLUSTER_NAME 

export MODEL_BUCKET=${PROJECT_ID}-bucket
gsutil mb gs://${MODEL_BUCKET}

gsutil cp -r gs://spls/gsp777/resnet_101 gs://${MODEL_BUCKET}


echo $MODEL_BUCKET
sed -i "s/your-bucket-name/$MODEL_BUCKET/g" tf-serving/configmap.yaml

kubectl apply -f tf-serving/configmap.yaml

cat tf-serving/deployment.yaml

kubectl apply -f tf-serving/deployment.yaml

kubectl get deployments

cat tf-serving/service.yaml


kubectl apply -f tf-serving/service.yaml

kubectl get svc image-classifier

kubectl autoscale deployment image-classifier \
--cpu-percent=60 \
--min=1 \
--max=4 


kubectl get hpa





echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}On Completing the Lab !!!${RESET}"


echo
echo -e "${CYAN}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo -e "${YELLOW}${BOLD_TEXT}          Subscribe To Arcade Labs          ${RESET_FORMAT}"
echo -e "${CYAN}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo