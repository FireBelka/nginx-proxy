#!/bin/bash
az login --service-principal -u "..." -p "..." --tenant "..."
az acr webhook delete -n 'nginxProxyBackendWebhook' -r '<registry>'
az acr webhook delete -n 'nginxProxynginxProxyServiceWebhookWebhook' -r '<registry>'
terraform destroy -auto-approve
