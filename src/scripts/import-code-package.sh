#! /bin/bash
export PATH=$PATH/bin

# Delete old artifacts
CODE_PACKAGE_NAME=mlops-churn-prediction-46
rm -f /tmp/${CODE_PACKAGE_NAME}.zip
pushd ~/${CODE_PACKAGE_NAME} > /dev/null
zip -r /tmp/${CODE_PACKAGE_NAME}.zip *
popd > /dev/null

BASE_SPACE_NAME=mlops-churn-prediction
TS=$(date +"%Y%m%d%H%M%S")
SPACE_NAME=${BASE_SPACE_NAME}-${TS}

# Create space
echo "Creating space ${SPACE_NAME}"
SPACE_ID=$(cpdctl space create --name ${SPACE_NAME} --output json --raw-output --jmes-query "metadata.id")
echo "The new space is $SPACE_NAME, id $SPACE_ID"

# Create code package in space
echo "Creating code package ${CODE_PACKAGE_NAME} in space ${SPACE_NAME}"
cpdctl asset file upload --path code_package/${CODE_PACKAGE_NAME} \
    --file /tmp/${CODE_PACKAGE_NAME}.zip \
    --space-id ${SPACE_ID}

CODE_PACKAGE_ID=$(cpdctl code-package create \
    --file-reference code_package/${CODE_PACKAGE_NAME} \
    --name ${CODE_PACKAGE_NAME} \
    --space-id ${SPACE_ID} \
    --output json -j "metadata.asset_id" --raw-output)

# Create job
environment_name="Runtime 22.2 on Python 3.10"
query_string="(resources[?entity.environment.display_name == '${environment_name}'].metadata.asset_id)[0]"
ENVIRONMENT_ID=$(cpdctl environment list --space-id ${SPACE_ID} --output json -j "${query_string}" --raw-output)

job_name="train-churn-prediction-job
job=''
job+='{"asset_ref": "'
job+="${CODE_PACKAGE_ID}"
job+='"}'
echo $job | jq .