#!/usr/bin/env bash

# exit on error even if parts of a pipe fail
set -e -o pipefail

###### Inputs ######
ENV=$1
if [[ "${ENV}" == "prod" ||  "${ENV}" == "preprod" ]]; then ACCOUNT_TYPE="prod"; else ACCOUNT_TYPE="nonprod"; fi
ACCOUNT_ID=$(jq -r .account_ids[\"${ACCOUNT_TYPE}\"] ../common.tfvars.json)
echo "We take account_type: '${ACCOUNT_TYPE}' and account ID: '${ACCOUNT_ID}' this time."
APP=$(jq -r .app ../common.tfvars.json)
SERVICE=$(jq -r .service ../common.tfvars.json)

###### Input checks ######

if [[ -z "${AWS_PROFILE}" ]]; then
    export AWS_PROFILE=$(jq -r .profiles.${ACCOUNT_TYPE} ../common.tfvars.json)
    echo "Environment variable AWS_PROFILE not set. Using '${AWS_PROFILE}' as profile."
fi

if [[ -z "${AWS_REGION}" ]]; then
  export AWS_REGION=$(jq -r .region ../common.tfvars.json)
  echo "Environment variable AWS_REGION not set. Using '${AWS_REGION}' as default."
fi


###### Main ######

echo "Check if aws credentials are valid"
aws sts get-caller-identity

# select workspace or setup workspace, if it is unknown locally
terraform workspace select "${ENV}-${SERVICE}" || ./init.sh ${ENV}

terraform destroy \
  -var-file=../common.tfvars.json \
  -var "env=${ENV}"