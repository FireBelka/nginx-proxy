#!/bin/bash
sudo apt update -y && sudo apt upgrade -y && sudo apt install curl -y
sudo  curl -fsSL -L https://get.docker.com | bash
sudo sudo apt install docker-compose -y
sudo curl -L https://raw.githubusercontent.com/docker/compose-cli/main/scripts/install/install_linux.sh | sh
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get install gnupg2 pass -y
az login --service-principal -u .. -p .. -t ..
sudo az acr login -n <reg-name>
cd /home/azureuser/
sudo chmod +x init-letsencrypt.sh
sudo ./init-letsencrypt.sh
#sudo docker-compose up -d
