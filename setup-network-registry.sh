echo "This script removes all private keys and registry events and generates new ones."
read -p "Do you want to continue? [Yes/No]" choice

if [[ $choice != "Yes" ]]; then
  exit
fi

echo deleting keys...
rm $(pwd)/config/bundy/keys/*
rm $(pwd)/config/dahmer/keys/*

echo deleting registry events...
rm $(pwd)/config/registry/events/*

echo starting docker
# Make sure there is a yaml
cp ./config/bundy/nuts.yaml.template ./config/bundy/nuts.yaml
cp ./config/dahmer/nuts.yaml.template ./config/dahmer/nuts.yaml

nohup docker-compose up dahmer-nuts-service-space bundy-nuts-service-space >/dev/null &
# store pid in variable
bg_pid=$!
# on exit, kill ngrok
trap "kill -2 $bg_pid" EXIT

echo waiting for containers to come up
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

# Register 1st vendor
read -p "Enter first Vendor name: " VENDOR_FIRST
docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 register-vendor urn:oid:1.3.6.1.4.1.54851.4:00000001 "${VENDOR_FIRST}" \
> /dev/null

# Register 2nd vendor
read -p "Enter second vendor name: " VENDOR_SECOND
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-vendor urn:oid:1.3.6.1.4.1.54851.4:00000002 "${VENDOR_SECOND}" \
> /dev/null

echo adding "${ORGANIZATION_1_NAME}" to ${VENDOR_FIRST}
docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 vendor-claim urn:oid:1.3.6.1.4.1.54851.4:00000001 urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} "${ORGANIZATION_1_NAME}" \
> /dev/null

echo adding "${ORGANIZATION_2_NAME}" to ${VENDOR_SECOND}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 vendor-claim urn:oid:1.3.6.1.4.1.54851.4:00000002 urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} "${ORGANIZATION_2_NAME}" \
> /dev/null

echo adding "${ORGANIZATION_3_NAME}" to ${VENDOR_SECOND}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 vendor-claim urn:oid:1.3.6.1.4.1.54851.4:00000002 urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} "${ORGANIZATION_3_NAME}" \
> /dev/null



echo adding endpoints for ${ORGANIZATION_1_NAME}
docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:80" -p authorizationServerURL="http://bundy-nuts-service-space:1323" \
> /dev/null

docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:nuts:endpoint:consent "tcp://bundy:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_bundy \
> /dev/null

docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:oid:1.3.6.1.4.1.54851.1:nuts-sso "http://localhost:80" -p authorizationServerURL="http://bundy-nuts-service-space:1323" \
> /dev/null

echo adding endpoints for ${ORGANIZATION_2_NAME}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:81" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null

docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:nuts:endpoint:consent "tcp://dahmer:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer \
> /dev/null

docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:oid:1.3.6.1.4.1.54851.1:nuts-sso "http://localhost:81" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null

echo adding endpoints for ${ORGANIZATION_3_NAME}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:82" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null

docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:nuts:endpoint:consent "tcp://dahmer:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer \
> /dev/null

docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:oid:1.3.6.1.4.1.54851.1:nuts-sso "http://localhost:82" -p authorizationServerURL="http://dahmer-nuts-service-space:1323" \
> /dev/null
