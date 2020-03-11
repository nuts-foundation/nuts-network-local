docker_cmd="docker-compose up"

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed. This local network consists of a lot of docker containers.' >&2
  echo 'download it here: https://docs.docker.com/compose/install/'
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed. We need it for parsing json output in this bash script.' >&2
  echo 'download it here: https://stedolan.github.io/jq/'
  exit 1
fi

if ! [ -x "$(command -v ngrok)" ]; then
  echo 'Error: ngrok is not installed. We need it for exposing your local irma server to a mobile phone.' >&2
  echo 'download it here: https://stedolan.github.io/jq/'
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

# start up ngrok
echo starting ngrok...
nohup ngrok start -config ./ngrok.yml bundy dahmer > /dev/null &
# store pid in variable
bg_pid=$!
# on exit, kill ngrok
trap "kill -2 $bg_pid" EXIT

# wait until ngrok has setup it connections
sleep 3

# retrieve public urls for bundy and dahmer
bundy_public_url=$(curl -s localhost:4040/api/tunnels | jq '.tunnels[] | select(.proto == "https") | select(.name == "bundy") | .public_url')
dahmer_public_url=$(curl -s localhost:4040/api/tunnels | jq '.tunnels[] | select(.proto == "https") | select(.name == "dahmer") | .public_url')

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
