# Kudulab's GoCD Agent Docker image

This is a [GoCD agent](https://www.gocd.io) docker image based on offical [GoCD ubuntu-18.04 docker image](https://github.com/gocd/docker-gocd-agent-ubuntu-18.04).

It is an *opinionated* variant with several enhancements:
 * Uses [s6 for init system](https://github.com/just-containers/s6-overlay) in the container
 * Image runs a docker daemon (so you end up with docker in docker)
 * Uses [Dojo](https://github.com/kudulab/dojo) and associated practices to provide sufficient tools of any projects. TL;DR: you don't need to install anything on the agent image.
 * In addition to configuration via environment variables, it's possible to obtain [secrets](#secret-store) from AWS SSM store or HashiCorp Vault.
 * It can handle temporary unavailability of the gocd server by restarting agent daemon in case it crashes.

# Project status

This is a WIP in attempt to make a generic agent that is flexible enough to fit everyone. I'm trying to gather best pieces from various GoCD deployments that I did before. Feel free to try out and comment.

# Secret store

If you don't want the image to setup secrets on start, just set `GOCD_SKIP_SECRETS=true`.

Otherwise the image expects that you have provided all required secrets via environment variables or specified  `SECRET_STORE`.

Required environment variables (when `SECRET_STORE` is not set):
 * AGENT_AUTO_REGISTER_KEY
 * GOCD_SSH_KEY

`SECRET_STORE` is not set by default, it can be either `aws` or `vault`, see lower for details.

## AWS

When using AWS secret store, the image expects that SSM paramemeter store contains:
 * `${AWS_SECRET_STORE_PATH}/autoregistration_key`
 * `${AWS_SECRET_STORE_PATH}/go_id_rsa` - with SSH private key that should be given to the agent (for git access over ssh)

You can configure `SSM_SECRET_STORE_PATH`, by default it's `gocd`.

You *must* specify following environment variables:
 * AWS_REGION

## Vault

When using vault secret store, the image expects that vault KV store contains:
 * `${VAULT_SECRET_STORE_PATH}/autoregistration_key`
 * `${VAULT_SECRET_STORE_PATH}/go_id_rsa` - with SSH private key that should be given to the agent (for git access over ssh)

You can configure `VAULT_SECRET_STORE_PATH`, by default it's `gocd`.

You *must* specify following environment variables:
 * VAULT_TOKEN
 * VAULT_ADDR

# Usage

Start the container with this:

```
docker run -d -e GO_SERVER_URL=... kudulab/gocd-agent
```

This will start the GoCD agent and connect it the GoCD server specified by `GO_SERVER_URL`.

> **Note**: The `GO_SERVER_URL` must be an HTTPS url and end with `/go`, for e.g. `http://ip.add.re.ss:8153/go`

## Demo with docker GoCD server

To start a [gocd-server container](https://hub.docker.com/r/gocd/gocd-server/) named `gocd_server`:
```
docker run -ti -p8153:8153 -p8154:8154 --name gocd_server gocd/gocd-server:v20.2.0
```

You can connect a gocd-agent container to it by doing:

```
docker run -ti --rm --link gocd_server:gocd-server  -e GO_SERVER_URL=http://gocd-server:8153/go -e AGENT_AUTO_REGISTER_KEY=abc -e GOCD_SSH_KEY=a --privileged --name agent kudulab/gocd-agent
```

*Beware of [SSL changes in 20.2](https://github.com/gocd/gocd/issues/7872)*

# Available configuration options

## Auto-registering the agents

```
docker run -d \
        -e AGENT_AUTO_REGISTER_KEY=... \
        -e AGENT_AUTO_REGISTER_RESOURCES=... \
        -e AGENT_AUTO_REGISTER_ENVIRONMENTS=... \
        -e AGENT_AUTO_REGISTER_HOSTNAME=... \
        kudulab/gocd-agent
```

If the `AGENT_AUTO_REGISTER_*` variables are provided (we recommend that you do), then the agent will be automatically approved by the server. See the [auto registration docs](https://docs.gocd.org/20.2.0/advanced_usage/agent_auto_register.html) on the GoCD website.

## Configuring SSL

To configure SSL parameters, pass the parameters using the environment variable `AGENT_BOOTSTRAPPER_ARGS`. See [this documentation](https://docs.gocd.org/20.2.0/installation/ssl_tls/end_to_end_transport_security.html) for supported options.

```shell
    docker run -d \
    -e AGENT_BOOTSTRAPPER_ARGS='-sslVerificationMode NONE ...' \
    kudulab/gocd-agent
```

## Mounting volumes

The GoCD agent will store all configuration, logs and perform builds in `/godata`. If you'd like to provide secure credentials like SSH private keys among other things, you can mount `/home/go`.

```
docker run -v /path/to/godata:/godata -v /path/to/home-dir:/home/go kudulab/gocd-agent
```

## Tweaking JVM options (memory, heap etc)

JVM options can be tweaked using the environment variable `GOCD_AGENT_JVM_OPTS`.

```
docker run -e GOCD_AGENT_JVM_OPTS="-Dfoo=bar" kudulab/gocd-agent
```

# Under the hood

The GoCD server runs as the `go` user, the location of the various directories is:

| Directory           | Description                                                                      |
|---------------------|----------------------------------------------------------------------------------|
| `/godata/config`    | the directory where the GoCD configuration is store                              |
| `/godata/pipelines` | the directory where the agent will run builds                                    |
| `/godata/logs`      | the directory where GoCD logs will be written out to                             |
| `/home/go`          | the home directory for the GoCD server                                           |

# Troubleshooting

## The GoCD agent does not connect to the server

- Check if the docker container is running `docker ps -a`
- Check the STDOUT to see if there is any output that indicates failures `docker logs CONTAINER_ID`
- Check the agent logs `docker exec -it CONTAINER_ID /bin/bash`, then run `less /godata/logs/*.log` inside the container.
