#!/usr/bin/with-contenv bash

set -eo pipefail

GOCD_HOME=/home/go
AGENT_WORK_DIR="/go"

function read_secret_or_die {
  local vault_key=$1

  if [ -z "${SECRET_STORE}" ]; then
    echo "Secret store is not selected. Can't obtain secret: ${vault_key}" >&2
    exit 1
  elif [ "${SECRET_STORE}" == "vault" ]; then
    echo "Trying to read from vault: ${vault_key}." >&2
    if [ -z "$VAULT_TOKEN" ]; then
      echo "Failed reading from vault: VAULT_TOKEN is not set." >&2
      exit 1
    fi
    if [ -z "$VAULT_ADDR" ]; then
      echo "Failed reading from vault: VAULT_ADDR is not set." >&2
      exit 1
    fi
    vault kv get --field=value secret/${VAULT_SECRET_STORE_PATH}/${vault_key}
    if [ $? != 0 ]; then
      echo "Failed reading from vault: ${vault_key}" >&2
      exit 1
    else
      echo "Successfully read from vault: ${vault_key}" >&2
    fi
  elif [ "${SECRET_STORE}" == "aws" ]; then
    echo "Trying to read from aws: ${vault_key}." >&2
    if [ -z "$AWS_REGION" ]; then
      echo "Failed reading from aws: AWS_REGION is not set." >&2
      exit 1
    fi
    aws ssm get-parameter --with-decryption --region $AWS_REGION --name /${AWS_SECRET_STORE_PATH}/${vault_key} | jq -r ".Parameter.Value"
    if [ $? != 0 ]; then
      echo "Failed reading from aws: /${AWS_SECRET_STORE_PATH}/${vault_key}" >&2
      exit 1
    else
      echo "Successfully read from aws: /${AWS_SECRET_STORE_PATH}/${vault_key}" >&2
    fi
  else
    echo "Invalid or unsupported secret store: ${SECRET_STORE}" >&2
    exit 1
  fi


}

if [[ "${!GOCD_SKIP_SECRETS[@]}" ]]; then
  echo "GOCD_SKIP_SECRETS is set - will not setup go's access to most of services"
  exit 0;
fi
if [ -z "$AGENT_AUTO_REGISTER_KEY" ]; then
  echo "AGENT_AUTO_REGISTER_KEY is not set but is needed for agent to autoregister. Falling back to secret store." >&2
  # the variables exported here are not visible in services' run files
  AGENT_AUTO_REGISTER_KEY=$(read_secret_or_die "autoregistration_key")
fi
if [ -z "$GOCD_SSH_KEY" ]; then
  echo "GOCD_SSH_KEY is not set. It is needed for go agent to use git over ssh. Falling back to secret store." >&2
  GOCD_SSH_KEY=$(read_secret_or_die "go_id_rsa")
fi

echo "export AGENT_AUTO_REGISTER_KEY=${AGENT_AUTO_REGISTER_KEY}" >${GOCD_HOME}/gocd_AGENT_AUTO_REGISTER_KEY

# quotes are required to keep multiline file
mkdir -p ${GOCD_HOME}/.ssh/
echo "$GOCD_SSH_KEY" >${GOCD_HOME}/.ssh/id_rsa
chmod 0600 ${GOCD_HOME}/.ssh/id_rsa

chown go:go -R ${GOCD_HOME}/.ssh
