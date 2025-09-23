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


echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress...${RESET}"


export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

PROJECT_ID=`gcloud config get-value project`

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

git clone https://github.com/Redislabs-Solution-Architects/gcp-microservices-demo-qwiklabs.git
pushd gcp-microservices-demo-qwiklabs

cat <<EOF > terraform.tfvars
gcp_project_id = "$(gcloud config list project \
 --format='value(core.project)')"
gcp_region = "$REGION"
EOF

terraform init

terraform apply -auto-approve

export REDIS_DEST=`terraform output db_private_endpoint | tr -d '"'`
export REDIS_DEST_PASS=`terraform output db_password | tr -d '"'`
export REDIS_ENDPOINT="${REDIS_DEST},user=default,password=${REDIS_DEST_PASS}"

gcloud container clusters get-credentials \
$(terraform output -raw gke_cluster_name) \
--region $(terraform output -raw region)

kubectl get service frontend-external -n redis

kubectl config set-context --current --namespace=redis

kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: redis-creds
type: Opaque
stringData:
  REDIS_SOURCE: redis://redis-cart:6379
  REDIS_DEST: redis://${REDIS_DEST}
  REDIS_DEST_PASS: ${REDIS_DEST_PASS}
EOF

kubectl apply -f https://raw.githubusercontent.com/Redislabs-Solution-Architects/gcp-microservices-demo-qwiklabs/main/util/redis-migrator-job.yaml

kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq 

kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"'$REDIS_ENDPOINT'"}]}]}}}}'

kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq


kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"redis-cart:6379"}]}]}}}}'

kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"'$REDIS_ENDPOINT'"}]}]}}}}'

kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq

kubectl delete deploy redis-cart

echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Process Completed !!!${RESET}"

echo
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo -e "${YELLOW}${BOLD}         Subscribe To Arcade Labs          ${RESET}"
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo








