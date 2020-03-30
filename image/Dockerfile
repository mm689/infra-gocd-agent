ARG gocd_version=v20.2.0
FROM gocd/gocd-agent-ubuntu-18.04:$gocd_version

USER root

# Nano, curl is for humans administrating/experimenting.
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends\
  git tzdata wget curl ca-certificates nano cron tar zip unzip bzip2 sudo rsync apt-transport-https ssh-client make &&\
  apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean &&\
  rm -rf /tmp/* /var/tmp/* && rm -rf /var/lib/apt/lists/*

RUN git clone --branch 0.4.0 https://github.com/kudulab/ops-base.git /tmp/ops-base &&\
   cd /tmp/ops-base/setup &&\
   ./install.sh &&\
   cd / && rm -rf /python-ops

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
  unzip awscliv2.zip &&\
  ./aws/install &&\
  rm -rf awscliv2.zip ./aws

RUN wget -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.1/s6-overlay-amd64.tar.gz &&\
  tar xvfz /tmp/s6-overlay.tar.gz -C / &&\
  rm -f /tmp/s6-overlay.tar.gz
ENTRYPOINT ["/init"]

# Install Docker
# To support docker in docker on any driver - clean up now and
# declare volume to bypass any storage drivers
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&\
  add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" &&\
  apt-get update &&\
  apt-get install -y docker-ce docker-ce-cli containerd.io &&\
  rm -Rf /var/lib/docker/* &&\
  rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* /var/tmp/*
VOLUME /var/lib/docker

ENV DOCKER_BASE_OPTS="--data-root=/var/lib/docker -H unix:///var/run/docker.sock"
ENV DOCKER_OPTS="--storage-driver overlay2"

ENV TERM="xterm"

COPY go-identity /home/go/
COPY ssh_config /etc/ssh/ssh_config
# Go uid should be 1000 for efficiency.
RUN userdel go &&\
  groupadd go --gid 1000 &&\
  useradd go --uid 1000 --gid 1000 --home /home/go --shell /bin/bash --password "$1$JJsvHslasdfjVEroftprNn4JHtDi" &&\
  mkdir -p /home/go && chmod 0755 /home/go &&\
  mkdir -p /home/go/.ssh && chmod 0700 /home/go/.ssh &&\
  chmod 0755 /home/go/.bashrc /home/go/.bashrc.d /home/go/.profile &&\
  chmod 0600 /home/go/.bashrc.d/* &&\
  chown go:go -R /home/go &&\
  usermod -aG docker go

# Add all the services
COPY ./services.d /etc/services.d
COPY run-on-start/* /etc/cont-init.d/

# Setup periodic cleanup of containers and images
COPY docker-gc.sh /usr/bin/docker-gc
COPY docker-gc.cron /etc/cron.d/docker-gc
RUN chmod -c 644 /etc/cron.d/docker-gc && crontab

ENV LC_ALL=C.UTF-8 \
  LANG=C.UTF-8

ENV SECRET_STORE="" \
  VAULT_SECRET_STORE_PATH=gocd \
  AWS_SECRET_STORE_PATH=gocd

# https://github.com/just-containers/s6-overlay#customizing-s6-behaviour
# Stop the container if cont-init scripts fail
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
