#!/usr/bin/with-contenv bash

set -e

if [[ "${!AGENT_SUDO_CONFIG[@]}" ]]; then
  echo "go ${AGENT_SUDO_CONFIG}" >> /etc/sudoers
  if ! visudo -c; then
    s6-svscanctl -t /var/run/s6/services
    exit 7;
  fi
fi
