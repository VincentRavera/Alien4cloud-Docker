#!/bin/bash

# Inspired by https://raw.githubusercontent.com/alien4cloud/alien4cloud.github.io/sources/files/1.4.0/getting_started.sh

# PostStart function for init getting started
postStart() {

    cd $INSTALL_DIR
    echo "Waiting for alien4cloud to start"
    until $(curl --output /dev/null --silent --head --fail http://localhost:8088); do
      printf '.'
      sleep 5
    done

    ALIEN_URL="http://localhost:8088"
    ALIEN_LOGIN="admin"
    ALIEN_PWD="admin"

    echo "Initializing getting started data"
    curl -c curlcookie.txt "$ALIEN_URL/login?username=$ALIEN_LOGIN&password=$ALIEN_PWD&submit=Login" \
    -XPOST \
    -H 'Content-Type: application/x-www-form-urlencoded'

    echo "Create puccini orchestrator"
    ORCHESTRATORID=`curl "$ALIEN_URL/rest/latest/orchestrators" \
    -b curlcookie.txt \
    -XPOST \
    -H 'Content-Type: application/json; charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"name":"Puccini simple orchestrator","pluginId":"alien4cloud-plugin-puccini","pluginBean":"puccini-orchestrator"}' | \
        python -c "import sys, json; print json.load(sys.stdin)['data']"`

    echo "Created orchestrator with id $ORCHESTRATORID"

    echo "Update orchestrator configuration"
    curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/configuration" \
    -XPUT \
    -s -b curlcookie.txt \
    -H 'Content-Type: application/json; charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary "{\"pucciniHome\":\"$INSTALL_DIR/$PUCCINI_DIR\"}"

    echo "Enable orchestrator (takes a few secs as it checks and configure puccini)"
    curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/instance" \
    -XPOST \
    -s -b curlcookie.txt \
    -H 'Content-Type: application/json; charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{}'

    sleep 5

    echo "Create local docker location"
    LOCATIONID=`curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/locations" \
    -XPOST \
    -b curlcookie.txt \
    -H 'Content-Type: application/json; charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"name":"Local docker","infrastructureType":"Docker"}' | \
        python -c "import sys, json; print json.load(sys.stdin)['data']"`

    echo "Created location $LOCATIONID"

    echo "Creating compute location resource"
    RESOURCEID=`curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/locations/$LOCATIONID/resources" \
    -XPOST \
    -b curlcookie.txt \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"resourceType":"org.alien4cloud.puccini.docker.nodes.Container","resourceName":"New resource","archiveName":"puccini-docker-provider-types","archiveVersion":"'$ALIEN4CLOUD_VERSION'","id":"org.alien4cloud.puccini.docker.nodes.Container:'$ALIEN4CLOUD_VERSION'"}' | \
        python -c "import sys, json; print json.load(sys.stdin)['data']['resourceTemplate']['id']"`

    echo "Configure template $RESOURCEID"
    curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/locations/$LOCATIONID/resources/$RESOURCEID/template/properties" \
    -XPOST \
    -s -b curlcookie.txt \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"propertyName":"image_id","propertyValue":"alien4cloud/puccini-ubuntu-trusty"}'

    curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/locations/$LOCATIONID/resources/$RESOURCEID/template/capabilities/os/properties" \
    -XPOST \
    -s -b curlcookie.txt \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"propertyName":"architecture","propertyValue":"x86_64"}'

    curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/locations/$LOCATIONID/resources/$RESOURCEID/template/capabilities/os/properties" \
    -XPOST \
    -s -b curlcookie.txt \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"propertyName":"type","propertyValue":"linux"}'

    curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/locations/$LOCATIONID/resources/$RESOURCEID/template/capabilities/os/properties" \
    -XPOST \
    -s -b curlcookie.txt \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"propertyName":"distribution","propertyValue":"ubuntu"}'

    curl "$ALIEN_URL/rest/latest/orchestrators/$ORCHESTRATORID/locations/$LOCATIONID/resources/$RESOURCEID" \
    -XPUT \
    -s -b curlcookie.txt \
    -H 'Content-Type: application/json; charset=UTF-8' \
    -H 'Accept: application/json, text/plain, */*' \
    --data-binary '{"name":"Ubuntu"}'

    echo "Open your browser and go to http://localhost:8088."
}

# Setting ENVS

ALIEN4CLOUD_VERSION=1.4.3.1
FASTCONNECT_REPOSITORY=opensource
INSTALL_DIR="/root/alien4cloud-getstarted/alien4cloud"

echo "Import common docker images"
COMMON_IMAGES=(alien4cloud/puccini-deployer-base:1.0.0-alpine alien4cloud/puccini-deployer:${ALIEN4CLOUD_VERSION} alien4cloud/puccini-ubuntu-trusty)
for image in $COMMON_IMAGES
do
    TEST=$(docker image ls $image | wc -l)
    if [ "$TEST" -lt 2 ]
    then
        echo "Pulling common image: $image"
        docker pull $image
    fi
done

postStart > /tmp/a4c_postStart &
echo "Starting alien4cloud"
cd $INSTALL_DIR
./alien4cloud.sh 2>&1 | tee /tmp/a4c.log

