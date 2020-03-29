#!/usr/bin/with-contenv bash

if [ -n "$TZ" ]; then
  echo "TZ is set to $TZ, reconfiguring package tzdata"
  ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
  dpkg-reconfigure --frontend noninteractive tzdata
else
  echo "TZ is not set, will not touch timezone configuration"
fi
