#!/bin/bash
#az acr login -n testRegK8s
#az account list
terraform apply -auto-approve
VAR1=$(az webapp deployment container config --enable-cd true -n '<web-app-name>' -g '<RG>' --slot 'staging' | jq '.CI_CD_URL' | tr -d '"')
az acr webhook create -n '<webhook-name>' -r '<Registry name>' --uri $VAR1 --actions push --scope <ACR-repository>:latest
