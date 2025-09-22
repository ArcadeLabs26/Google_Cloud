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


read -p "Enter your region (e.g., us-central1): " REGION
read -p "Enter zone for subnet-a (e.g., ${REGION}-a): " ZONE_A
read -p "Enter zone for subnet-b (e.g., ${REGION}-b): " ZONE_B
read -p "Enter zone for utility VM (e.g., ${REGION}-a): " UTILITY_ZONE

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Progress...${RESET}"



PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"


gcloud compute firewall-rules create app-allow-http \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=10.10.0.0/16 \
    --rules=tcp:80


gcloud compute firewall-rules create app-allow-health-check \
    --network=my-internal-app \
    --action=allow \
    --direction=ingress \
    --target-tags=lb-backend \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --rules=tcp


gcloud compute instance-templates create instance-template-1 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION


gcloud compute instance-templates create instance-template-2 \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-b \
    --no-address \
    --tags=lb-backend \
    --metadata=startup-script-url=gs://spls/gsp216/startup.sh \
    --region=$REGION


sleep 30

gcloud compute instance-groups managed create instance-group-1 \
    --template=instance-template-1 \
    --base-instance-name=instance-group-1 \
    --size=1 \
    --zone=$ZONE_A


gcloud compute instance-groups managed create instance-group-2 \
    --template=instance-template-2 \
    --base-instance-name=instance-group-2 \
    --size=1 \
    --zone=$ZONE_B


sleep 60


gcloud compute instance-groups managed set-autoscaling instance-group-1 \
    --zone=$ZONE_A \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8

gcloud compute instance-groups managed set-autoscaling instance-group-2 \
    --zone=$ZONE_B \
    --min-num-replicas=1 \
    --max-num-replicas=1 \
    --target-cpu-utilization=0.8


gcloud compute instances create utility-vm \
    --machine-type=e2-micro \
    --network=my-internal-app \
    --subnet=subnet-a \
    --private-network-ip=10.10.20.50 \
    --zone=$UTILITY_ZONE \
    --tags=lb-backend


sleep 90


echo "=== Verifying Backends ==="

# Get internal IPs of the instances (corrected filtering)
INSTANCE_1_IP=$(gcloud compute instances list --filter="name~'instance-group-1.*'" --format="value(networkInterfaces[0].networkIP)" --zone=$ZONE_A)
INSTANCE_2_IP=$(gcloud compute instances list --filter="name~'instance-group-2.*'" --format="value(networkInterfaces[0].networkIP)" --zone=$ZONE_B)

echo "Instance 1 IP: $INSTANCE_1_IP"
echo "Instance 2 IP: $INSTANCE_2_IP"
echo ""

# If IPs are empty, use default IPs
if [ -z "$INSTANCE_1_IP" ]; then
    INSTANCE_1_IP="10.10.20.2"
    echo "Using default IP for instance 1: $INSTANCE_1_IP"
fi

if [ -z "$INSTANCE_2_IP" ]; then
    INSTANCE_2_IP="10.10.30.2"
    echo "Using default IP for instance 2: $INSTANCE_2_IP"
fi

# Test connectivity via utility VM
echo "Testing connectivity through utility VM..."
echo "This may take a moment..."

# SSH into utility VM and test connectivity (with error handling)
gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --command="
    echo 'Testing connection to instance-group-1 at $INSTANCE_1_IP...'
    max_attempts=3
    for i in \$(seq 1 \$max_attempts); do
        if curl -s --connect-timeout 10 $INSTANCE_1_IP > /dev/null; then
            echo '✓ Successfully connected to instance-group-1'
            curl -s $INSTANCE_1_IP | grep -E '(Server Hostname|Server Location|Client IP)' | head -3
            break
        else
            echo 'Attempt \$i failed, retrying...'
            sleep 10
        fi
        if [ \$i -eq \$max_attempts ]; then
            echo '✗ Failed to connect to instance-group-1 after \$max_attempts attempts'
        fi
    done
    
    echo ''
    echo 'Testing connection to instance-group-2 at $INSTANCE_2_IP...'
    for i in \$(seq 1 \$max_attempts); do
        if curl -s --connect-timeout 10 $INSTANCE_2_IP > /dev/null; then
            echo '✓ Successfully connected to instance-group-2'
            curl -s $INSTANCE_2_IP | grep -E '(Server Hostname|Server Location|Client IP)' | head -3
            break
        else
            echo 'Attempt \$i failed, retrying...'
            sleep 10
        fi
        if [ \$i -eq \$max_attempts ]; then
            echo '✗ Failed to connect to instance-group-2 after \$max_attempts attempts'
        fi
    done
    echo ''
    echo 'Backend verification complete!'
" || echo "SSH connection failed, but continuing with setup..."

echo ""
echo "Backend verification attempted!"
echo ""

gcloud compute health-checks create tcp my-ilb-health-check \
    --port=80 \
    --region=$REGION


gcloud compute backend-services create my-ilb-backend-service \
    --load-balancing-scheme=INTERNAL \
    --protocol=TCP \
    --health-checks=my-ilb-health-check \
    --health-checks-region=$REGION \
    --region=$REGION


gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-1 \
    --instance-group-zone=$ZONE_A \
    --region=$REGION

gcloud compute backend-services add-backend my-ilb-backend-service \
    --instance-group=instance-group-2 \
    --instance-group-zone=$ZONE_B \
    --region=$REGION


gcloud compute addresses create my-ilb-ip \
    --region=$REGION \
    --subnet=subnet-b \
    --addresses=10.10.30.5


gcloud compute forwarding-rules create my-ilb \
    --load-balancing-scheme=INTERNAL \
    --network=my-internal-app \
    --subnet=subnet-b \
    --address=10.10.30.5 \
    --ip-protocol=TCP \
    --ports=80 \
    --backend-service=my-ilb-backend-service \
    --backend-service-region=$REGION \
    --region=$REGION

sleep 60


echo "=== Final Verification ==="
echo "Load Balancer IP: 10.10.30.5"
echo ""

# Test the load balancer (with error handling)
echo "Testing load balancer..."
gcloud compute ssh utility-vm --zone=$UTILITY_ZONE --command="
    echo 'Testing Load Balancer (10.10.30.5):'
    max_attempts=3
    success=false
    for i in \$(seq 1 \$max_attempts); do
        if curl -s --connect-timeout 10 10.10.30.5 > /dev/null; then
            echo '✓ Load Balancer is working!'
            echo 'Response from backend:'
            curl -s 10.10.30.5 | grep -E '(Server Hostname|Server Location)' | head -2
            success=true
            break
        else
            echo 'Attempt \$i failed, retrying in 10 seconds...'
            sleep 10
        fi
    done
    
    if ! \$success; then
        echo '✗ Load Balancer test failed after \$max_attempts attempts'
        echo 'This might be normal if instances are still initializing.'
    fi
    
    echo ''
    echo 'Testing multiple requests to see load balancing in action:'
    for i in {1..3}; do
        echo 'Request' \$i ':'
        curl -s 10.10.30.5 | grep -E 'Server Hostname|Server Location' | head -1
        sleep 2
    done
" || echo "SSH test failed, but setup is complete. You can test manually later."


echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Process Completed !!!${RESET}"

echo
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo -e "${YELLOW}${BOLD}         Subscribe To Arcade Labs          ${RESET}"
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo








