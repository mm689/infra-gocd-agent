#!/usr/bin/with-contenv bash

# Ensure the go user has specified uid and gid if they were set
# as GOCD_UID and GOCD_GID.

echo "Start."
set -e

if [[ -z "${GOCD_UID}" ]] || [[ -z "${GOCD_GID}" ]]; then
  echo "Either GOCD_UID or GOCD_GID not set. Will not change any UID/GID."
  exit 0
fi

newuid="${GOCD_UID}"
newgid="${GOCD_GID}"
gocd_user="go"
gocd_group="go"
olduid=$(id ${gocd_user} --user)
oldgid=$(id ${gocd_group} --group)

echo "olduid is: ${olduid}; oldgid is: ${oldgid}"
echo "newuid is: ${newuid}; newgid is: ${newgid}"

if [[ "${newuid}" == "${olduid}" ]] && [[ "${newgid}" == "${oldgid}" ]]; then
  echo "Nothing to do. Exit now."
  exit 0
else
  echo "Updating user: go."
  set -x
  usermod -u "${newuid}" "${gocd_user}"
  groupmod -g "${newgid}" "${gocd_group}"
  set +x
fi

echo "Done."
