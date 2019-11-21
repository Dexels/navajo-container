#!/bin/sh
rm -rf plugins *.zip
mkdir plugins
BRANCH=newmaven
NAVAJO_VERSION=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/navajo?circle-token=${CIRCLE_TOKEN}&limit=1&offset=0&filter=successful" | jq '.[0].build_num')
ENTERPRISE_VERSION=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/enterprise?circle-token=${CIRCLE_TOKEN}&limit=1&offset=0&filter=successful" | jq '.[0].build_num')
echo "versions: $NAVAJO_VERSION - ${ENTERPRISE_VERSION} - ${SPORTLINKLIBRARY_VERSION}"
curl -s "https://${NAVAJO_VERSION}-4423334-gh.circle-artifacts.com/0/navajo_p2.zip?circle-token=$CIRCLE_TOKEN&branch=${BRANCH}" -o navajo_p2.zip
curl -s "https://${ENTERPRISE_VERSION}-4423339-gh.circle-artifacts.com/0/enterprise_p2.zip?circle-token=$CIRCLE_TOKEN&branch=${BRANCH}"  -o enterprise_p2.zip
ls *.zip | xargs -I '{}' unzip -o '{}'
rm -rf artifacts.* content.* features* *.index
rm *.zip
docker build . -t dexels/nav:latest
docker push dexels/nav:latest

