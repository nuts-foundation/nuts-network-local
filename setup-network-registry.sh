#!/bin/bash
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
rm $(pwd)/config/dahmer/keys/*
rm $(pwd)/config/bundy/keys/*

echo deleting registry events...
rm $(pwd)/config/registry/events/*

echo starting docker
# Make sure there is a nuts.yaml and the nuts.yaml is not a directory
# This can happen when docker compose tries to mount a non existing file
rm -r ./config/*/nuts.yaml
cp ./config/bundy/nuts.yaml.template ./config/bundy/nuts.yaml
cp ./config/dahmer/nuts.yaml.template ./config/dahmer/nuts.yaml

VENDOR_FIRST_ID=urn:oid:1.3.6.1.4.1.54851.4:00000001
VENDOR_SECOND_ID=urn:oid:1.3.6.1.4.1.54851.4:00000002

nohup docker-compose up dahmer-nuts-service-space bundy-nuts-service-space discovery >/dev/null &

echo waiting for containers to come up
# Make sure containers are created (Ubuntu 20 fix)
sleep 1
retry=0
healthy=0
while [ $retry -lt 30 ]; do
  bundyHealthStatus=$(docker inspect -f {{.State.Health.Status}} $(docker-compose ps -q bundy-nuts-service-space))
  dahmerHealthStatus=$(docker inspect -f {{.State.Health.Status}} $(docker-compose ps -q dahmer-nuts-service-space))
  discoveryHealthStatus=$(docker inspect -f {{.State.Health.Status}} $(docker-compose ps -q discovery))

  if [[ "$bundyHealthStatus" == "healthy" && "$dahmerHealthStatus" == "healthy" && "$discoveryHealthStatus" == "healthy" ]]; then
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

# args: node-name (dahmer | bundy), vendor-id, vendor-name
function registerVendor {
  nodeName=$1
  containerName=$1-nuts-service-space
  vendorID=$2
  vendorName=$3
  echo "Registering vendor ${vendorName} (${vendorID}) on ${nodeName}..."
  echo " 1. Generating CSR..."
  docker-compose exec -e NUTS_MODE=cli "${containerName}" \
    nuts crypto generate-vendor-csr "${vendorName}" /opt/nuts/keys/vendorca-csr.pem
  echo Sending CSR to Network Authority to get it to issue a certificate...
  docker-compose exec "${containerName}" \
    curl -X POST -H "Content-Type: text/plain" --data-binary @/opt/nuts/keys/vendorca-csr.pem http://discovery:8080/api/csr
  echo " 2. Retrieving certificate..."
  docker-compose exec "${containerName}" \
    curl -s "http://discovery:8080/api/x509?otherName=${vendorID}" \
    | jq -j '.[0].certificate' > "./config/${nodeName}/keys/vendorca-cert.pem"
  echo " 3. Registering vendor CA certificate..."
  docker-compose exec -e NUTS_MODE=cli "${containerName}" \
    nuts registry register-vendor /opt/nuts/keys/vendorca-cert.pem
}

# args: node-name (dahmer | bundy), AGB-code, organization-name
function registerOrganization {
  nodeName=$1
  containerName=$1-nuts-service-space
  agbCode=$2
  orgName=$3
  echo adding "${orgName}" to "${nodeName}"
  docker-compose exec -e NUTS_MODE=cli "${containerName}" \
    nuts registry vendor-claim "urn:oid:2.16.840.1.113883.2.4.6.1:${agbCode}" "${orgName}"
}

# args: node-name (dahmer | bundy), organization AGB-code, endpoint-type, endpoint-url, endpoint-id, properties
function registerEndpoint {
  containerName=$1-nuts-service-space
  agbCode=$2
  endpointType=$3
  endpointURL=$4
  endpointID=$5
  endpointProps=$6
  echo "adding endpoint for ${agbCode}: type=${endpointType}, URL: ${endpointURL}, ID: ${endpointID}, properties: ${endpointProps}"
  docker-compose exec -e NUTS_MODE=cli "${containerName}" \
    nuts registry register-endpoint "urn:oid:2.16.840.1.113883.2.4.6.1:${agbCode}" "${endpointType}" "${endpointURL}" -i "${endpointID}" -p "${endpointProps}"
}

#
# Register vendors
#
read -p "Enter first Vendor name: " VENDOR_FIRST
read -p "Enter second vendor name: " VENDOR_SECOND
registerVendor bundy "${VENDOR_FIRST_ID}" "${VENDOR_FIRST}"
registerVendor dahmer "${VENDOR_SECOND_ID}" "${VENDOR_SECOND}"

#
# Register organizations
#
registerOrganization bundy  "${ORGANIZATION_1_AGB}" "${ORGANIZATION_1_NAME}"
registerOrganization dahmer "${ORGANIZATION_2_AGB}" "${ORGANIZATION_2_NAME}"
registerOrganization dahmer "${ORGANIZATION_3_AGB}" "${ORGANIZATION_3_NAME}"

#
# Register endpoints
#
registerEndpoint bundy  "${ORGANIZATION_1_AGB}" "urn:oid:1.3.6.1.4.1.54851.2:demo-ehr" "http://demo-ehr:8000"  ""                                                                         "authorizationServerURL=http://bundy-nuts-service-space:1323"
registerEndpoint bundy  "${ORGANIZATION_1_AGB}" "urn:nuts:endpoint:consent"            "tcp://bundy:7886"      "urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_bundy"  ""
registerEndpoint bundy  "${ORGANIZATION_1_AGB}" "urn:oid:1.3.6.1.4.1.54851.1:nuts-sso" "http://localhost:8000" ""                                                                         "authorizationServerURL=http://bundy-nuts-service-space:1323"
registerEndpoint dahmer "${ORGANIZATION_2_AGB}" "urn:oid:1.3.6.1.4.1.54851.2:demo-ehr" "http://demo-ehr:8001"  ""                                                                         "authorizationServerURL=http://dahmer-nuts-service-space:1323"
registerEndpoint dahmer "${ORGANIZATION_2_AGB}" "urn:nuts:endpoint:consent"            "tcp://dahmer:7886"     "urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer" ""
registerEndpoint dahmer "${ORGANIZATION_2_AGB}" "urn:oid:1.3.6.1.4.1.54851.1:nuts-sso" "http://localhost:8001" ""                                                                         "authorizationServerURL=http://dahmer-nuts-service-space:1323"
registerEndpoint dahmer "${ORGANIZATION_3_AGB}" "urn:oid:1.3.6.1.4.1.54851.2:demo-sso" "http://demo-ehr:8002"  ""                                                                         "authorizationServerURL=http://dahmer-nuts-service-space:1323"
registerEndpoint dahmer "${ORGANIZATION_3_AGB}" "urn:nuts:endpoint:consent"            "tcp://dahmer:7886"     "urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer" ""
registerEndpoint dahmer "${ORGANIZATION_3_AGB}" "urn:oid:1.3.6.1.4.1.54851.1:nuts-sso" "http://localhost:8002" ""                                                                         "authorizationServerURL=http://dahmer-nuts-service-space:1323"

echo "Restarting containers"
# Required for:
# 1. Nuts Network to load the Vendor CA certificate for issuing a TLS certificate, to go online
# 2. Nuts Registry to load all registry events from both nodes in order
docker-compose restart
