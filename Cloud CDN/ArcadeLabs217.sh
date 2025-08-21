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

export PROJECT_ID=$(gcloud config get-value project)

export BUCKET_NAME="$PROJECT_ID"

gsutil mb -l US gs://$BUCKET_NAME

gsutil cp gs://cloud-training/gcpnet/cdn/cdn.png gs://$BUCKET_NAME

gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME

# Get the access token
TOKEN_ID=$(gcloud auth application-default print-access-token)


# Create a Backend Bucket
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_ID" \
  -d '{
    "bucketName": "'"$PROJECT_ID"'",
    "cdnPolicy": {
      "cacheMode": "CACHE_ALL_STATIC",
      "clientTtl": 60,
      "defaultTtl": 60,
      "maxTtl": 60,
      "negativeCaching": false,
      "serveWhileStale": 0
    },
    "compressionMode": "DISABLED",
    "description": "",
    "enableCdn": true,
    "name": "cdn-bucket"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendBuckets"

sleep 15

# Create a URL map for the CDN load balancer
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_ID" \
  -d '{
    "defaultService": "projects/'"$PROJECT_ID"'/global/backendBuckets/cdn-bucket",
    "name": "cdn-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/urlMaps"


sleep 15

# Create a target HTTP proxy for the CDN load balancer
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_ID" \
  -d '{
    "name": "cdn-lb-target-proxy",
    "urlMap": "projects/'"$PROJECT_ID"'/global/urlMaps/cdn-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/targetHttpProxies"

sleep 15

# Create a forwarding rule for the CDN load balancer
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_ID" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV4",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "cdn-lb-forwarding-rule",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$PROJECT_ID"'/global/targetHttpProxies/cdn-lb-target-proxy"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/forwardingRules"




echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Setup Completed !!!${RESET}"


echo
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo -e "${YELLOW}${BOLD}           Subscribe To Arcade Labs           ${RESET}"
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo