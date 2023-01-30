#!/usr/bin/env bash

# exit on error even if parts of a pipe fail
set -e -o pipefail

###### Inputs ######
ENV=$1
if [[ "${ENV}" == "prod" ||  "${ENV}" == "preprod" ]]; then ACCOUNT_TYPE="prod"; else ACCOUNT_TYPE="nonprod"; fi
ACCOUNT_ID=$(jq -r .account_ids[\"${ACCOUNT_TYPE}\"] ../common.tfvars.json)
echo "We take account_type: '${ACCOUNT_TYPE}' and account ID: '${ACCOUNT_ID}' this time."
SERVICE=$(jq -r .service ../common.tfvars.json)

###### Input checks ######
if [[ -z "${ACCOUNT_TYPE}" ]]; then
    echo "Please set ACCOUNT_TYPE as first parameter (e.g. nonprod, ..)"
    exit 1
fi

if [[ -z "${AWS_REGION}" ]]; then
    export AWS_REGION=$(jq -r .region ../common.tfvars.json)
    echo "Environment variable AWS_REGION not set. Using '${AWS_REGION}' as default."
fi

# assume to target account if running on codebuild
if [ -n "${CODEBUILD_SRC_DIR}" ]; then
  echo "Using codebuild role."
else
  echo "Using workstation credentials."
  if [[ -z "${AWS_PROFILE}" ]]; then
      export AWS_PROFILE=$(jq -r .profiles.${ACCOUNT_TYPE} ../common.tfvars.json)
      echo "Environment variable AWS_PROFILE not set. Using '${AWS_PROFILE}' as profile."
  fi
fi

###### Main ######
aws sts get-caller-identity

# select workspace or setup workspace, if it is unknown locally
terraform workspace select "${ENV}-${SERVICE}" || ./init.sh ${ENV}

if [ -n "${CODEBUILD_SRC_DIR}" ]; then
    terraform plan \
      -var-file=../common.tfvars.json \
      -var "region=${AWS_REGION}" \
      -var "env=${ENV}" \
      -var "account_type=${ACCOUNT_TYPE}" \
      -no-color \
      -out plan.out

    terraform apply \
      -no-color \
      plan.out
else
    terraform apply \
      -var-file=../common.tfvars.json \
      -var "region=${AWS_REGION}" \
      -var "account_type=${ACCOUNT_TYPE}" \
      -var "env=${ENV}"
fi
