#! /bin/bash
export PATH=$PATH:$HOME/bin

env

BASE_REPO_NAME=$(basename ${REPO_NAME})
BASE_SPACE_NAME=${BASE_REPO_NAME}
ENVIRONMENT_NAME="Runtime 22.2 on Python 3.10"

CODE_PACKAGE_NAME=${BASE_REPO_NAME}
NOTEBOOK="src/train-churn-prediction.ipynb"

JOB_DESCRIPTION="Train churn prediction"
JOB_NAME="train-churn-prediction-job"

# Delete old artifacts
rm -f /tmp/${CODE_PACKAGE_NAME}.zip

# Create zip file from current directory
zip -r /tmp/${CODE_PACKAGE_NAME}.zip *

# Create space
TS=$(date +"%Y%m%d%H%M%S")
space_name=${BASE_SPACE_NAME}-${CURRENT_BRANCH}-${TS}
echo "Creating space ${space_name}"
space_id=$(cpdctl space create --name ${space_name} --output json --raw-output --jmes-query "metadata.id")
echo "Space ${space_name} created with id ${space_id}"

# Create code package in space
echo "Creating code package ${CODE_PACKAGE_NAME} in space ${space_name}"
cpdctl asset file upload --path code_package/${CODE_PACKAGE_NAME} \
    --file /tmp/${BASE_REPO_NAME}.zip \
    --space-id ${space_id}

code_package_id=$(cpdctl code-package create \
    --file-reference code_package/${CODE_PACKAGE_NAME} \
    --name ${CODE_PACKAGE_NAME} \
    --space-id ${space_id} \
    --output json -j "metadata.asset_id" --raw-output)

# Create job
echo "Creating job ${JOB_NAME} with environment ${ENVIRONMENT_NAME}"
query_string="(resources[?entity.environment.display_name == '${ENVIRONMENT_NAME}'].metadata.asset_id)[0]"
environment_id=$(cpdctl environment list --space-id ${space_id} --output json -j "${query_string}" --raw-output)

job_json='{
    "asset_ref": "%s", 
    "configuration": 
        {
            "env_id": "%s", 
            "env_variables": ["CURRENT_BRANCH=%s"], 
            "entrypoint": "%s" }, 
    "description": "%s", 
    "name": "%s"
    }\n'
job_submit_json=$(printf "${job_json}" "${code_package_id}" "${environment_id}" "${CURRENT_BRANCH}" "${NOTEBOOK}" "${JOB_DESCRIPTION}" "${JOB_NAME}")
echo "Job submit JSON: ${job_submit_json}"

job_id=$(cpdctl job create --job "${job_submit_json}" --space-id ${space_id} --output json -j "metadata.asset_id" --raw-output)

# Run job
echo "Running job"
job_run_id=$(cpdctl job run create --space-id ${space_id} --job-id ${job_id} --job-run '{}' --output json -j "metadata.asset_id" --raw-output)
echo "Job run id: ${job_run_id}"

# Delete temporary space
cpdctl space delete --space-id ${space_id}

echo "Finished"