#!/bin/bash
az acr webhook delete -n '<webhook-name>' -r '<reg-name>'
terraform destroy -auto-approve
