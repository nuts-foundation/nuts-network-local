ORGANIZATION_1_NAME="Verpleeghuis De Nootjes"
ORGANIZATION_1_AGB=12345678

ORGANIZATION_2_NAME="Huisartsenpraktijk Nootenboom"
ORGANIZATION_2_AGB=87654321

ORGANIZATION_3_NAME="Medisch Centrum Noot aan de Man"
ORGANIZATION_3_AGB=43215678

echo deleting keys...
rm $(pwd)/config/bundy/keys/*
rm $(pwd)/config/dahmer/keys/*

echo deleting registry events...
rm $(pwd)/config/registry/events/*

echo registering new vendors

# Register 1st vendor
echo Enter first Vendor name
read VENDOR_FIRST
docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 register-vendor urn:oid:1.3.6.1.4.1.54851.4:00000001 "${VENDOR_FIRST}"

# Register 2nd vendor
echo Enter second vendor name
read VENDOR_SECOND
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-vendor urn:oid:1.3.6.1.4.1.54851.4:00000002 "${VENDOR_SECOND}"

echo adding "${ORGANIZATION_1_NAME}" to ${VENDOR_FIRST}
docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 vendor-claim urn:oid:1.3.6.1.4.1.54851.4:00000001 urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} "${ORGANIZATION_1_NAME}"

echo adding "${ORGANIZATION_2_NAME}" to ${VENDOR_SECOND}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 vendor-claim urn:oid:1.3.6.1.4.1.54851.4:00000002 urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} "${ORGANIZATION_2_NAME}"
# NUTS_MODE=cli ./nuts-go registry register-endpoint --registry.address=localhost:11323 urn:oid:2.16.840.1.113883.2.4.6.1:43215678 urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:82"

echo adding "${ORGANIZATION_3_NAME}" to ${VENDOR_SECOND}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 vendor-claim urn:oid:1.3.6.1.4.1.54851.4:00000002 urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} "${ORGANIZATION_3_NAME}"

# NUTS_MODE=cli ./nuts-go registry register-endpoint --registry.address=localhost:11323 urn:oid:2.16.840.1.113883.2.4.6.1:43215678 urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:82"

echo adding endpoints for ${ORGANIZATION_1_NAME}
docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:80" -p authorizationServerURL="http://bundy-nuts-service-space:1323"

docker run \
--mount type=bind,source="$(pwd)/config/bundy/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/bundy/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/bundy/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=bundy-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_1_AGB} urn:nuts:endpoint:consent "tcp://bundy:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_bundy

echo adding endpoints for ${ORGANIZATION_2_NAME}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:81" -p authorizationServerURL="http://dahmer-nuts-service-space:1323"

docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_2_AGB} urn:nuts:endpoint:consent "tcp://dahmer:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer

echo adding endpoints for ${ORGANIZATION_3_NAME}
docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:oid:1.3.6.1.4.1.54851.2:demo-ehr "http://demo-ehr:82" -p authorizationServerURL="http://dahmer-nuts-service-space:1323"

docker run \
--mount type=bind,source="$(pwd)/config/dahmer/nuts.yaml",target=/opt/nuts/nuts.yaml \
--mount type=bind,source="$(pwd)/config/registry",target=/opt/nuts/registry \
--mount type=bind,source="$(pwd)/nodes/dahmer/sqlite",target=/opt/nuts/sqlite \
--mount type=bind,source="$(pwd)/config/dahmer/keys",target=/opt/nuts/keys \
--env NUTS_CONFIGFILE=/opt/nuts/nuts.yaml \
--env NUTS_MODE=cli \
--network=nuts \
nutsfoundation/nuts-service-space:sso registry --registry.address=dahmer-nuts-service-space:1323 register-endpoint urn:oid:2.16.840.1.113883.2.4.6.1:${ORGANIZATION_3_AGB} urn:nuts:endpoint:consent "tcp://dahmer:7886" --id urn:ietf:rfc:1779:O=Nuts,C=NL,L=Groenlo,CN=nuts_corda_development_dahmer
