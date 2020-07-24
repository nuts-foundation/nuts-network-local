#!/bin/bash
SERVICE_SPACE_IMAGE=nutsfoundation/nuts-service-space:release-0.14.1
echo "This script removes all private keys and registry events and generates new ones."
read -p "Do you want to continue? [Yes/No]" choice

if [[ $choice != "Yes" ]]; then
  exit
fi

echo "stopping stack (if running)..."
docker-compose down
echo deleting databases...
rm $(pwd)/nodes/*/sqlite/*.db
echo deleting keys...
rm $(pwd)/config/*/keys/*

echo deleting registry events...
rm $(pwd)/config/registry/events/*

echo starting docker
# Make sure there is a nuts.yaml and the nuts.yaml is not a directory
# This can happen when docker compose tries to mount a non existing file
rm -r ./config/*/nuts.yaml
cp ./config/bundy/nuts.yaml.template ./config/bundy/nuts.yaml
cp ./config/dahmer/nuts.yaml.template ./config/dahmer/nuts.yaml

nohup docker-compose up dahmer-nuts-service-space bundy-nuts-service-space >/dev/null &

echo waiting for containers to come up
# Make sure containers are created (Ubuntu 20 fix)
sleep 1
retry=0
healthy=0
while [ $retry -lt 30 ]; do
  bundyHealthStatus=$(docker inspect -f {{.State.Health.Status}} $(docker-compose ps -q bundy-nuts-service-space))
  dahmerHealthStatus=$(docker inspect -f {{.State.Health.Status}} $(docker-compose ps -q dahmer-nuts-service-space))

  if [[ "$bundyHealthStatus" == "healthy" && "$dahmerHealthStatus" == "healthy" ]]; then
    healthy=1
    echo "started!"
    break
  fi

  printf "."
  sleep 0.5
  retry=$[$retry+1]
done

if [ $healthy -eq 0 ]; then
  echo containers took too much time to start
  exit 1
fi

ORGANIZATION_1_NAME="Verpleeghuis De Nootjes"
ORGANIZATION_1_AGB=12345678

ORGANIZATION_2_NAME="Huisartsenpraktijk Nootenboom"
ORGANIZATION_2_AGB=87654321

ORGANIZATION_3_NAME="Medisch Centrum Noot aan de Man"
ORGANIZATION_3_AGB=43215678

echo registering new vendors

#
# NOTICE: In 0.14 the registry defaults to 'server' mode while this should've been none, since it should derive it from
# the global mode configuration. That means even when the CLI is used (with NUTS_MODE=cli) the registry is started in
# server mode, causing errors. Workaround is to override this by setting NUTS_REGISTRY_MODE=client
# This is fixed for 0.15 so this environment variable set in the commands below can be removed.
#

#
# Register 1st vendor
#
read -p "Enter first Vendor name: " VENDOR_FIRST
docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=bundy-nuts-service-space:1323 register-vendor "${VENDOR_FIRST}" \
  > /dev/null

#
# Register 2nd vendor
#
read -p "Enter second vendor name: " VENDOR_SECOND
docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 register-vendor "${VENDOR_SECOND}" \
  > /dev/null

#
# Register organizations
#
echo adding "${ORGANIZATION_1_NAME}" to ${VENDOR_FIRST}
docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=bundy-nuts-service-space:1323 vendor-claim urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} "${ORGANIZATION_1_NAME}" \
  > /dev/null

echo adding "${ORGANIZATION_2_NAME}" to ${VENDOR_SECOND}
docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 vendor-claim urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} "${ORGANIZATION_2_NAME}" \
  > /dev/null

echo adding "${ORGANIZATION_3_NAME}" to ${VENDOR_SECOND}
docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 vendor-claim urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} "${ORGANIZATION_3_NAME}" \
  > /dev/null

#
# Register endpoints
#
echo adding endpoints for ${ORGANIZATION_1_NAME}
docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:8000" -p authorizationServerURL="http://bundy-nuts-service-space:1323" \
  > /dev/null

docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:nuts:endpoint:consent "tcp://bundy:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_bundy \
  > /dev/null

docker run \
  --env NUTS_MODE=cli \
  --env NUTS_REGISTRY_MODE=client \
  --network=nuts \
  $SERVICE_SPACE_IMAGE registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:oid:1.3.6.1.4.1.54851.1:nuts-sso "http://localhost:8000" -p authorizationServerURL="http://bundy-nuts-service-space:1323" \
  > /dev/null

echo adding endpoints for ${ORGANIZATION_2_NAME}
docker run \
--env NUTS_MODE=cli \
--env NUTS_REGISTRY_MODE=client \
--network=nuts \
$SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:8001" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null

docker run \
--env NUTS_MODE=cli \
--env NUTS_REGISTRY_MODE=client \
--network=nuts \
$SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:nuts:endpoint:consent "tcp://dahmer:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer \
> /dev/null

docker run \
--env NUTS_MODE=cli \
--env NUTS_REGISTRY_MODE=client \
--network=nuts \
$SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:oid:1.3.6.1.4.1.54851.1:nuts-sso "http://localhost:8001" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null

echo adding endpoints for ${ORGANIZATION_3_NAME}
docker run \
--env NUTS_MODE=cli \
--env NUTS_REGISTRY_MODE=client \
--network=nuts \
$SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:8002" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null

docker run \
--env NUTS_MODE=cli \
--env NUTS_REGISTRY_MODE=client \
--network=nuts \
$SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:nuts:endpoint:consent "tcp://dahmer:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer \
> /dev/null

docker run \
--env NUTS_MODE=cli \
--env NUTS_REGISTRY_MODE=client \
--network=nuts \
$SERVICE_SPACE_IMAGE registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:oid:1.3.6.1.4.1.54851.1:nuts-sso "http://localhost:8002" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null

echo "Restarting containers"
# Required for:
# 1. Nuts Network to load the Vendor CA certificate for issuing a TLS certificate, to go online
# 2. Nuts Registry to load all registry events from both nodes in order
docker-compose restart
