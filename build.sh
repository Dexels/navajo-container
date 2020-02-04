#!/bin/sh

NAME=$(basename $0)
BRANCH="master"
PUSH=""

while getopts :b:p opt ; do
    case $opt in
        b) BRANCH="$OPTARG" ;;
        p) PUSH="push" ;;
        ?) echo "$NAME: Unknown option '$OPTARG'" ; exit 1 ;;
    esac
done

if [ -z "$CIRCLE_TOKEN" ]; then
    echo "$NAME: Error, CIRCLE_TOKEN not set."
    exit 1
fi


NAVAJO_BRANCH="$BRANCH"
ENTERPRISE_BRANCH="$BRANCH"
TAG_PREFIX=3.3


echo "$NAME: Retrieving version numbers"

BASE_CONTAINER_BUILD=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/dexels-base?circle-token=${CIRCLE_TOKEN}&limit=1&offset=0&filter=successful" | jq '.[0].build_num')
TAG=${TAG_PREFIX}.${BASE_CONTAINER_BUILD}

NAVAJO_VERSION=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/navajo?circle-token=${CIRCLE_TOKEN}&limit=1&offset=0&filter=successful" | jq '.[0].build_num')

ENTERPRISE_VERSION=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/enterprise?circle-token=${CIRCLE_TOKEN}&limit=1&offset=0&filter=successful" | jq '.[0].build_num')


echo "$NAME: Docker tag for parent image: ${TAG}"
echo "$NAME: Navajo Version: $NAVAJO_VERSION - Enterprise Version: ${ENTERPRISE_VERSION}"

rm -rf plugins *.zip
mkdir plugins


echo "$NAME: Downloading ZIPs"

curl -s "https://${NAVAJO_VERSION}-4423334-gh.circle-artifacts.com/0/navajo_p2.zip?circle-token=$CIRCLE_TOKEN&branch=${BRANCH}" -o navajo_p2.zip

curl -s "https://${ENTERPRISE_VERSION}-4423339-gh.circle-artifacts.com/0/enterprise_p2.zip?circle-token=$CIRCLE_TOKEN&branch=${BRANCH}"  -o enterprise_p2.zip


echo "$NAME: Extracting ZIPs"

ls *.zip | xargs -I '{}' unzip -o '{}'
rm -rf artifacts.* content.* features* *.index
rm *.zip


echo "$NAME: Building docker image"
docker  build  --build-arg TAG=$TAG  .  -t dexels/nav:latest

if [ -n "$PUSH" ]; then
    echo "$NAME: Pusing docker image to docker hub"
    docker  push  dexels/navajo-container-manual:latest
fi

