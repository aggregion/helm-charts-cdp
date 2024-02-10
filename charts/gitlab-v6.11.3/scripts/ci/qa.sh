#!/bin/bash

# In the event we don't have `CI_PIPELINE_CREATED_AT`, mock it consistently.
export QA_SCRIPT_SOURCED_DATE=`date --universal --iso-8601=seconds`

function qa_export_passwords() {
  for x in {1..6}; do
    export "GITLAB_QA_PASSWORD_${x}"="$(qa_generate_password $x)"
  done
}


# password is sha256sum of:
# - CI_PIPELINE_CREATED_AT, which is stable, but unique per pipeline
# - CI_COMMIT_REF_SLUG, which is stable between pipelines
# - Input user "number" if provided
function qa_generate_password() {
  USER=${1:-1}
  REF=${CI_COMMIT_REF_SLUG:-abcdef12345678}
  CREATED=${CI_PIPELINE_CREATED_AT:-QA_SCRIPT_SOURCED_DATE}

  echo -n "${REF}-${CREATED}-${USER}" | sha256sum -t - | cut -f1 -d' '
}