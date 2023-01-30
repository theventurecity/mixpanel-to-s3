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

TF_WORKSPACE_KEY_PREFIX="envs"
TF_STATE_KEY="${APP}-${SERVICE}-ecs"

###### Input checks ######
if [[ -z "${ACCOUNT_TYPE}" ]]; then
    echo "Please set ACCOUNT_NAME as first parameter (e.g. nonprod, ..)"
    exit 1
fi

if [ -n "${CODEBUILD_SRC_DIR}" ]; then
  echo "Using codebuild role."
  PIPELINE_INIT_ARGS="-no-color"
else
  echo "Using workstation credentials."
  if [[ -z "${AWS_PROFILE}" ]]; then
      export AWS_PROFILE=$(jq -r .profiles.${ACCOUNT_TYPE} ../common.tfvars.json)
      echo "Environment variable AWS_PROFILE not set. Using '${AWS_PROFILE}' as profile."
  fi
fi

if [[ -z "${AWS_REGION}" ]]; then
    export AWS_REGION=$(jq -r .region ../common.tfvars.json)
    echo "Environment variable AWS_REGION not set. Using '${AWS_REGION}' as default."
fi

###### Main ######
aws sts get-caller-identity

# fresh init
rm -rf .terraform
# configure s3 backend for terraform remote state
# s3 encryption is done by bucket and not by terraform (encrypt=false)
terraform init \
${PIPELINE_INIT_ARGS} \
-backend-config="role_arn=arn:aws:iam::${ACCOUNT_ID}:role/${APP}-${SERVICE}-${ENV}-deployer" \
-backend-config="profile=${AWS_PROFILE}" \
-backend-config="region=${AWS_REGION}" \
-backend-config="bucket=terraform-state-${ACCOUNT_ID}-${AWS_REGION}" \
-backend-config="key=${TF_STATE_KEY}.tfstate" \
-backend-config="workspace_key_prefix=${TF_WORKSPACE_KEY_PREFIX}" \
-backend-config="dynamodb_table=terraform-state-lock" \
-backend-config="encrypt=false"

echo "Create workspace ${ENV}-${SERVICE}, if it does not exist"
terraform workspace new "${ENV}-${SERVICE}" || true
terraform workspace select "${ENV}-${SERVICE}"