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


show_spinner() {
    local pid=$!
    local delay=0.1
    local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

    tput civis
    while kill -0 $pid 2>/dev/null; do
        for char in "${spin_chars[@]}"; do
            printf "\r${char} $1 "
            sleep $delay
        done
    done
    tput cnorm
    printf "\r✔ $1 completed\n"
}

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"


gcloud services enable securitycenter.googleapis.com --quiet &
show_spinner "Enabling API"


export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

gcloud pubsub topics create projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
show_spinner "Creating Pub/Sub topic"

gcloud pubsub subscriptions create export-findings-pubsub-topic-sub \
  --topic=projects/$PROJECT_ID/topics/export-findings-pubsub-topic &
show_spinner "Creating Pub/Sub subscription"


echo
echo "Please create the export configuration:"
echo "https://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=${PROJECT_ID}"
echo

# Step 4: User confirmation before proceeding
while true; do
    read -p "Do you want to proceed? (Y/n): " confirm
    case "$confirm" in
        [Yy]|"") 
            echo "Continuing with setup..."
            break
            ;;
        [Nn]) 
            echo "Operation canceled."
            exit 0
            ;;
        *) 
            echo "Invalid input. Please enter Y or N." 
            ;;
    esac
done


gcloud compute instances create instance-1 --zone=$ZONE \
  --machine-type=e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform &
show_spinner "Creating instance"


bq --location=$REGION mk --dataset $PROJECT_ID:continuous_export_dataset &
show_spinner "Creating dataset"

gcloud scc bqexports create scc-bq-cont-export \
  --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset \
  --project=$PROJECT_ID \
  --quiet &
show_spinner "Configuring BigQuery export"


for i in {0..2}; do
    gcloud iam service-accounts create sccp-test-sa-$i &
    show_spinner "Creating service account sccp-test-sa-$i"
    
    gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
    --iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com &
    show_spinner "Creating key for sccp-test-sa-$i"
done


# query_findings() {
#   bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
#     "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
# }

# has_findings() {
#   echo "$1" | grep -qE '^[|] [a-f0-9]{32} '
# }

# while true; do
#     result=$(query_findings)
    
#     if has_findings "$result"; then
#         echo "Findings detected!"
#         echo "$result"
#         break
#     else
#         echo "No findings yet. Waiting for 100 seconds..."
#         sleep 100
#     fi
# done


query_findings() {
  bq query --use_legacy_sql=false --format=json \
    "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings"
}


has_findings() {
  echo "$1" | jq -e 'length > 0' >/dev/null 2>&1
}


MAX_ATTEMPTS=3
attempt=1


while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo "Attempt $attempt of $MAX_ATTEMPTS..."
    
    result=$(query_findings)

    if has_findings "$result"; then
        echo "Findings detected!"
        echo "$result" | jq
        break
    else
        echo "No findings yet. Waiting for 100 seconds..."
        sleep 100
        attempt=$((attempt + 1))
    fi
done

if [ $attempt -gt $MAX_ATTEMPTS ]; then
    echo "No findings detected after $((MAX_ATTEMPTS * 100 / 60)) minutes. Exiting..."
    # exit 1
fi



gsutil mb -l $REGION gs://$BUCKET_NAME/ &
show_spinner "Creating bucket"

gsutil pap set enforced gs://$BUCKET_NAME &
show_spinner "Enabling public access prevention"

sleep 20


gcloud scc findings list "projects/$PROJECT_ID" \
  --format=json | jq -c '.[]' > findings.jsonl &
show_spinner "Exporting findings"

gsutil cp findings.jsonl gs://$BUCKET_NAME/ &
show_spinner "Uploading findings to bucket"


echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}On Completion !!!${RESET}"

echo
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo -e "${YELLOW}${BOLD}         Subscribe To Arcade Labs          ${RESET}"
echo -e "${CYAN}${BOLD}=============================================${RESET}"
echo








