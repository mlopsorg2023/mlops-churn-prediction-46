#! /bin/bash
BASE_PROJECT_NAME=$1
TAR_FILE=$2

TS=$(date +"%Y%m%d%H%M%S")
PROJECT_NAME=${BASE_PROJECT_NAME}-${TS}

# Create project
STORAGE_JSON='{"type": "assetfiles", "guid": "'$(uuidgen)'"}'
RESULT=$(/tmp/cpdctl/cpdctl project create --name ${PROJECT_NAME} --storage "$STORAGE_JSON" --output json --jmes-query 'location' --raw-output)
PROJECT_ID=$(basename $RESULT)
echo "The new project is $PROJECT_NAME, id $PROJECT_ID"


IMPORT_ID=$(/tmp/cpdctl/cpdctl asset import start --project-id ${PROJECT_ID} --import-file ${TAR_FILE} --output json --jmes-query "metadata.id" --raw-output)

/tmp/cpdctl/cpdctl asset import get --project-id ${PROJECT_ID} --import-id ${IMPORT_ID}