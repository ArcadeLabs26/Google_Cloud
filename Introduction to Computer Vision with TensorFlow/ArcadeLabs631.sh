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

python --version

pip3 install --upgrade pip
pip3 install tensorflow
pip install -U pylint --user
pip install -r requirements.txt

wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Introduction%20to%20Computer%20Vision%20with%20TensorFlow/model.ipynb
wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Introduction%20to%20Computer%20Vision%20with%20TensorFlow/callback_model.ipynb
wget https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Introduction%20to%20Computer%20Vision%20with%20TensorFlow/updated_model.ipynb



echo "${GREEN}${BOLD}Congratulations:- ${RESET}" "${WHITE}${BOLD}Setup Completed !!!${RESET}"


echo
echo -e "${YELLOW}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo -e "${WHITE}${BOLD_TEXT}            Subscribe To Arcade Labs          ${RESET_FORMAT}"
echo -e "${YELLOW}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo