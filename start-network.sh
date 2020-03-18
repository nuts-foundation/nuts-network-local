#!/bin/bash
docker_cmd="docker-compose up"

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed. This local network consists of a lot of docker containers.' >&2
  echo 'Download it here: https://docs.docker.com/compose/install/'
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed. We use it for parsing json output in this bash script.' >&2
  echo 'Download it here: https://stedolan.github.io/jq/'
  exit 1
fi

if ! [ -x "$(command -v ngrok)" ]; then
  echo 'Error: ngrok is not installed. We use it for exposing your local irma server to a mobile phone.' >&2
  echo 'Download it here: https://ngrok.com/download and put it somewhere in your PATH'
  exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed. We use it to extract active public_urls from ngrok' >&2
  exit 1
fi

if [ "$#" -ge 1 ]; then
  if [ "$1" == "minimal" ]; then
    docker_cmd="docker-compose up dahmer-nuts-service-space bundy-nuts-service-space"
  elif [ "$1" == "ehr" ]; then
    docker_cmd="docker-compose up dahmer-nuts-service-space bundy-nuts-service-space redis demo-ehr"
  else
    echo "usage: ./start-network.sh [minimal|ehr]"
    exit
  fi
fi

if [ ! -f ./ngrok.yml ]; then
  echo "No active ./ngrok.yml configuration found, let's create one"
  echo You need a ngrok auth token. Get one by creating a free account on ngrok.com
  read -p "token: " ngrok_token
  export NGROK_TOKEN=$ngrok_token
  envsubst < "./ngrok.yml.template" > "./ngrok.yml" 2>/dev/null
fi

# start up ngrok
echo starting ngrok...
nohup ngrok start -config ./ngrok.yml bundy dahmer > /dev/null &
# store pid in variable
bg_pid=$!
# on exit, kill ngrok
trap "kill -2 $bg_pid" EXIT

# wait until ngrok has setup it connections
sleep 3

# Create the nuts.yaml config

# First, remove the configs
rm -r ./config/bundy/nuts.yaml
rm -r ./config/dahmer/nuts.yaml

# retrieve public urls for bundy and dahmer
bundy_public_url=$(curl -s localhost:4040/api/tunnels | jq '.tunnels[] | select(.proto == "https") | select(.name == "bundy") | .public_url')
dahmer_public_url=$(curl -s localhost:4040/api/tunnels | jq '.tunnels[] | select(.proto == "https") | select(.name == "dahmer") | .public_url')

if [[ -z "$bundy_public_url" ]] || [[ -z "$dahmer_public_url" ]]; then
  echo "could not obtain public urls. Is ngrok correctly configured? Check your ngrok.yml and your token."
  exit 1
fi

echo public urls:
echo bundy_public_url: $bundy_public_url
echo dahmer_public_url: $dahmer_public_url

echo generating config files
export PUBLIC_URL=$bundy_public_url
envsubst < "./config/bundy/nuts.yaml.template" > "./config/bundy/nuts.yaml" 2>/dev/null

export PUBLIC_URL=$dahmer_public_url
envsubst < "./config/dahmer/nuts.yaml.template" > "./config/dahmer/nuts.yaml" 2>/dev/null

echo starting containers
$docker_cmd
