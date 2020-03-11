cordapp_version=0.12.0

if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed. This local network consists of a lot of docker containers.' >&2
  echo 'download it here: https://docs.docker.com/get-started/#set-up-your-docker-environment'
  exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed. It is needed to download the contracts, flows and bootstrapper tool.' >&2
  exit 1
fi


echo Nuts network bootstrapper with Corda apps v$cordapp_version

echo "WARNING: This script removes all existing corda nodes and generate new ones."
read -p "Do you want to continue? [Yes/No]" choice
if [[ $choice != "Yes" ]]; then
  exit
fi

cd nodes
echo "removing all nodes (if any)"
rm *.jar
rm -rf bundy
rm -rf dahmer
rm -rf notary

echo "download new cordapps of version $cordapp_version"
curl -O -s "https://repo1.maven.org/maven2/nl/nuts/consent/cordapp/flows/$cordapp_version/flows-$cordapp_version.jar"
curl -O -s "https://repo1.maven.org/maven2/nl/nuts/consent/cordapp/contract/$cordapp_version/contract-$cordapp_version.jar"

echo downloading corda network boostrapper
curl -s -O https://repo1.maven.org/maven2/net/corda/corda-tools-network-bootstrapper/4.3/corda-tools-network-bootstrapper-4.3.jar

echo "running bootstrapper (this may take a while)"
docker run --mount type=bind,source="$(pwd)",target=/opt/app openjdk:8-jdk-slim java -jar /opt/app/corda-tools-network-bootstrapper-4.3.jar --dir /opt/app --copy-cordapps=Yes

if [ $? -ne 0 ]; then
  echo bootstrapping failed >&2
  exit 1
fi

echo done
