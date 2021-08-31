# Nuts network local

This repo contains a set of properties, keys, config and other files for setting up a local nuts network. This is all connected together with docker-compose.yml files. You’ll need to have docker and docker-compose installed.

There are two setups in this repo: single and network. In `/single` you can find a docker-compose file that creates a single node with administrative interface and demo-ehr. In `/network` two nodes are created that communicate with each other.

The following chapters describe the commands when run from one of those sub-directories.

## Start/stop

make sure you've the latest docker images:

```shell
docker-compose pull
```

Then you can start the containers via:

```shell
docker-compose up
```
or detached
```shell
docker-compose up -d
```
in detached mode, you can view logs via `docker logs -f [container_name]`. The container name will be outputted to console.
and stop via CTRL-C or:

```shell
docker-compose down
```

## Reset

To reset all data in the network, remove:

```shell
data/admin/*
data/node/crypto/*
data/node/irma/*
data/node/network/*
data/node/vcr/*
```
