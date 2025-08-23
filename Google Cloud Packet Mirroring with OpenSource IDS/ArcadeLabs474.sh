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



echo "${MAGENTA}${BOLD}Please set the below values correctly${RESET}"
read -p "${YELLOW}${BOLD}Enter the ZONE: ${RESET}" ZONE

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress${RESET}"

progress "Setting compute zone to: $ZONE"
gcloud config set compute/zone $ZONE

export REGION="${ZONE%-*}"
progress "Extracted region: $REGION"

gcloud config set compute/region $REGION

# Network Infrastructure Setup
progress "Creating VPC network: dm-stamford"
gcloud compute networks create dm-stamford \
--subnet-mode=custom

progress "Creating primary subnet: dm-stamford-$REGION"
gcloud compute networks subnets create dm-stamford-$REGION \
--range=172.21.0.0/24 \
--network=dm-stamford \
--region=$REGION

progress "Creating IDS subnet: dm-stamford-$REGION-ids"
gcloud compute networks subnets create dm-stamford-$REGION-ids \
--range=172.21.1.0/24 \
--network=dm-stamford \
--region=$REGION

# Firewall Rules
progress "Creating firewall rule for web traffic"
gcloud compute firewall-rules create fw-dm-stamford-allow-any-web \
--direction=INGRESS \
--priority=1000 \
--network=dm-stamford \
--action=ALLOW \
--rules=tcp:80,icmp \
--source-ranges=0.0.0.0/0

progress "Creating firewall rule for IDS traffic"
gcloud compute firewall-rules create fw-dm-stamford-ids-any-any \
--direction=INGRESS \
--priority=1000 \
--network=dm-stamford \
--action=ALLOW \
--rules=all \
--source-ranges=0.0.0.0/0 \
--target-tags=ids

progress "Creating firewall rule for IAP proxy"
gcloud compute firewall-rules create fw-dm-stamford-iapproxy \
--direction=INGRESS \
--priority=1000 \
--network=dm-stamford \
--action=ALLOW \
--rules=tcp:22,icmp \
--source-ranges=35.235.240.0/20

# NAT Gateway
progress "Creating Cloud Router for NAT"
gcloud compute routers create router-stamford-nat-$REGION \
--region=$REGION \
--network=dm-stamford

progress "Configuring NAT gateway"
gcloud compute routers nats create nat-gw-dm-stamford-$REGION \
--router=router-stamford-nat-$REGION \
--router-region=$REGION \
--auto-allocate-nat-external-ips \
--nat-all-subnet-ip-ranges

# Web Server Instance Template
progress "Creating web server instance template"
gcloud compute instance-templates create template-dm-stamford-web-$REGION \
--region=$REGION \
--network=dm-stamford \
--subnet=dm-stamford-$REGION \
--machine-type=e2-small \
--image=ubuntu-1604-xenial-v20200807 \
--image-project=ubuntu-os-cloud \
--tags=webserver \
--metadata=startup-script='#! /bin/bash
  apt-get update
  apt-get install apache2 -y
  vm_hostname="$(curl -H "Metadata-Flavor:Google" \
  http://169.254.169.254/computeMetadata/v1/instance/name)"
  echo "Page served from: $vm_hostname" | \
  tee /var/www/html/index.html
  systemctl restart apache2'

progress "Creating web server managed instance group"
gcloud compute instance-groups managed create mig-dm-stamford-web-$REGION \
    --template=template-dm-stamford-web-$REGION \
    --size=2 \
    --zone=$ZONE

# IDS Instance Template
progress "Creating IDS instance template"
gcloud compute instance-templates create template-dm-stamford-ids-$REGION \
--region=$REGION \
--network=dm-stamford \
--no-address \
--subnet=dm-stamford-$REGION-ids \
--image=ubuntu-1604-xenial-v20200807 \
--image-project=ubuntu-os-cloud \
--tags=ids,webserver \
--metadata=startup-script='#! /bin/bash
  apt-get update
  apt-get install apache2 -y
  vm_hostname="$(curl -H "Metadata-Flavor:Google" \
  http://169.254.169.254/computeMetadata/v1/instance/name)"
  echo "Page served from: $vm_hostname" | \
  tee /var/www/html/index.html
  systemctl restart apache2'

progress "Creating IDS managed instance group"
gcloud compute instance-groups managed create mig-dm-stamford-ids-$REGION \
    --template=template-dm-stamford-ids-$REGION \
    --size=1 \
    --zone=$ZONE

# Load Balancer Setup
progress "Creating health check for TCP port 80"
gcloud compute health-checks create tcp hc-tcp-80 --port 80

progress "Creating backend service for Suricata IDS"
gcloud compute backend-services create be-dm-stamford-suricata-$REGION \
--load-balancing-scheme=INTERNAL \
--health-checks=hc-tcp-80 \
--network=dm-stamford \
--protocol=TCP \
--region=$REGION

progress "Adding backend to the service"
gcloud compute backend-services add-backend be-dm-stamford-suricata-$REGION \
--instance-group=mig-dm-stamford-ids-$REGION \
--instance-group-zone=$ZONE \
--region=$REGION

progress "Creating internal load balancer"
gcloud compute forwarding-rules create ilb-dm-stamford-suricata-ilb-$REGION \
--load-balancing-scheme=INTERNAL \
--backend-service be-dm-stamford-suricata-$REGION \
--is-mirroring-collector \
--network=dm-stamford \
--region=$REGION \
--subnet=dm-stamford-$REGION-ids \
--ip-protocol=TCP \
--ports=all

# Packet Mirroring
progress "Configuring packet mirroring for web traffic"
gcloud compute packet-mirrorings create mirror-dm-stamford-web \
--collector-ilb=ilb-dm-stamford-suricata-ilb-$REGION \
--network=dm-stamford \
--mirrored-subnets=dm-stamford-$REGION \
--region=$REGION

# Display created resources
progress "Displaying created resources..."
echo "${BOLD}VPC Networks:${RESET}"
gcloud compute networks list --filter="name:dm-stamford"

echo "${BOLD}Subnets:${RESET}"
gcloud compute networks subnets list --network=dm-stamford

echo "${BOLD}Firewall Rules:${RESET}"
gcloud compute firewall-rules list --filter="network:dm-stamford"

echo "${BOLD}Instance Groups:${RESET}"
gcloud compute instance-groups list --filter="name:mig-dm-stamford"




echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Lab Completed !!!${RESET}"


echo
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo -e "${YELLOW}${BOLD}           Subscribe To Arcade Labs           ${RESET}"
echo -e "${CYAN}${BOLD}================================================${RESET}"
echo