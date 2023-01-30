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
###### Declare variables ######
ZIP_FILE="${SERVICE}.zip"
BUILD_DIR="upload"
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
if [ -d ${BUILD_DIR} ]; then
    rm -r ${BUILD_DIR}
fi
mkdir ${BUILD_DIR}
pushd ${BUILD_DIR} > /dev/null
cd ../../../
git archive --format=zip tf -o tf/00-pipeline/upload/${ZIP_FILE}
aws s3 cp tf/00-pipeline/${BUILD_DIR}/${ZIP_FILE} s3://${APP}-${SERVICE}-${ENV}-pipeline-${ACCOUNT_ID}-${AWS_REGION}/${ZIP_FILE}
popd > /dev/null

rm -r ${BUILD_DIR}


