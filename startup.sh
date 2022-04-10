#!/bin/bash
#az acr login -n testRegK8s
az login --service-principal -u "..." -p "..." --tenant "..."
terraform apply -auto-approve
VAR1=$(az webapp deployment container config --enable-cd true -n '<app-name>' -g '<RG>' --slot 'staging' | jq '.CI_CD_URL' | tr -d '"')
az acr webhook create -n 'nginxProxyBackendWebhook' -r '<Registry>' --uri $VAR1 --actions push --scope nginx-backend:latest
az acr webhook create -n 'nginxProxyServiceWebhook' -r '<Registry>' --uri $VAR1 --actions push --scope nginx-proxy:latest
