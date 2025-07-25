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



gcloud config list project
export PROJECT_ID=$(gcloud config get-value project)
echo $PROJECT_ID
gcloud config set project $PROJECT_ID

gcloud compute networks create Network Name --subnet-mode custom

gcloud compute networks subnets create Subnet Name \
        --network Network Name --range 10.0.0.0/24 --region Region

gcloud compute firewall-rules create Firewall Name --allow tcp:3000 --network Network Name

gcloud compute firewall-rules create Firewall Name1 \
    --network=Network Name \
    --action=allow \
    --direction=ingress \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=allow-healthcheck \
    --rules=tcp

gcloud compute instances create-with-container vm_instance --container-image bkimminich/juice-shop \
     --network Network Name \
     --subnet Subnet Name \
     --private-network-ip=10.0.0.3 \
     --machine-type n1-standard-2 \
     --zone Zone \
     --tags allow-healthcheck

gcloud compute instance-groups unmanaged create Instance Group \
    --zone=Zone

gcloud compute instance-groups unmanaged add-instances Instance Group \
    --zone=Zone \
    --instances=VM Instance

gcloud compute instance-groups unmanaged set-named-ports \
Instance Group \
   --named-ports=http:3000 \
   --zone=Zone

gcloud compute health-checks create tcp tcp-port-3000 \
        --port 3000

gcloud compute backend-services create juice-shop-backend \
        --protocol HTTP \
        --port-name http \
        --health-checks tcp-port-3000 \
        --enable-logging \
        --global

 gcloud compute backend-services add-backend juice-shop-backend \
        --instance-group=Instance Group \
        --instance-group-zone=Zone \
        --global

gcloud compute url-maps create juice-shop-loadbalancer \
        --default-service juice-shop-backend

gcloud compute target-http-proxies create juice-shop-proxy \
        --url-map juice-shop-loadbalancer

gcloud compute forwarding-rules create juice-shop-rule \
        --global \
        --target-http-proxy=juice-shop-proxy \
        --ports=80

PUBLIC_SVC_IP="$(gcloud compute forwarding-rules describe juice-shop-rule  --global --format="value(IPAddress)")"
echo $PUBLIC_SVC_IP

curl -Ii http://$PUBLIC_SVC_IP

curl -Ii http://$PUBLIC_SVC_IP/ftp

curl -Ii http://$PUBLIC_SVC_IP/ftp?doc=/bin/ls

curl -Ii http://$PUBLIC_SVC_IP -H "User-Agent: blackwidow"

curl -Ii "http://$PUBLIC_SVC_IP/index.html?foo=advanced%0d%0aContent-Length:%200%0d%0a%0d%0aHTTP/1.1%20200%20OK%0d%0aContent-Type:%20text/html%0d%0aContent-Length:%2035%0d%0a%0d%0a<html>Sorry,%20System%20Down</html>"

curl -Ii http://$PUBLIC_SVC_IP -H session_id=X

gcloud compute security-policies list-preconfigured-expression-sets

gcloud compute security-policies create Policy Name \
    --description "Block with OWASP ModSecurity CRS"

gcloud compute security-policies rules update 2147483647 \
    --security-policy Policy Name \
    --action "deny-403"

MY_IP=$(curl ifconfig.me)

gcloud compute security-policies rules create 10000 \
    --security-policy Policy Name  \
    --description "allow traffic from my IP" \
    --src-ip-ranges "$MY_IP/32" \
    --action "allow"

gcloud compute security-policies rules create 9000 \
    --security-policy Policy Name  \
    --description "block local file inclusion" \
     --expression "evaluatePreconfiguredExpr('lfi-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9001 \
    --security-policy Policy Name  \
    --description "block rce attacks" \
     --expression "evaluatePreconfiguredExpr('rce-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9002 \
    --security-policy Policy Name  \
    --description "block scanners" \
     --expression "evaluatePreconfiguredExpr('scannerdetection-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9003 \
    --security-policy Policy Name  \
    --description "block protocol attacks" \
     --expression "evaluatePreconfiguredExpr('protocolattack-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9004 \
    --security-policy Policy Name \
    --description "block session fixation attacks" \
     --expression "evaluatePreconfiguredExpr('sessionfixation-stable')" \
    --action deny-403

gcloud compute backend-services update juice-shop-backend \
    --security-policy Policy Name \
    --global





echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Setup Completed !!!${RESET}"


echo
echo -e "${YELLOW}${BOLD}==============================================${RESET}"
echo -e "${WHITE}${BOLD}            Subscribe To Arcade Labs          ${RESET}"
echo -e "${YELLOW}${BOLD}==============================================${RESET}"
echo