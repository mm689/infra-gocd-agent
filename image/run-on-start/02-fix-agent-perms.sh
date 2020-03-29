#!/bin/bash

echo "Starting go-agent permissions fix"
set -x
cd /godata
mkdir -p pipelines config logs
chown go:go pipelines
chown go:go -R config
chown go:go -R logs
chown go:go -R "/home/go"
set +x
echo "Done go-agent permissions fix."
