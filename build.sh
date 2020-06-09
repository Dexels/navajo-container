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

CONTAINER_BUILD=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/dexels-base?circle-token=${CIRCLE_TOKEN}&limit=100&offset=0&filter=successful" | jq '[.[] | select(.workflows.job_name == "package")][0].build_num')
TAG=${TAG_PREFIX}.${CONTAINER_BUILD}
echo "$NAME: docker tag for parent image: ${TAG}"

BASE_VERSION=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/dexels-base?circle-token=${CIRCLE_TOKEN}&limit=100&offset=0&filter=successful" | jq '[.[] | select(.workflows.job_name == "build")][0].build_num')
echo "$NAME: dexels-base version: $BASE_VERSION"

NAVAJO_VERSION=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/navajo?circle-token=${CIRCLE_TOKEN}&limit=100&offset=0&filter=successful" | jq '[.[] | select(.branch == "master")][0].build_num')
echo "$NAME: navajo version: $NAVAJO_VERSION"

ENTERPRISE_VERSION=$(curl -s "https://circleci.com/api/v1.1/project/github/Dexels/enterprise?circle-token=${CIRCLE_TOKEN}&limit=100&offset=0&filter=successful" | jq '[.[] | select(.branch == "master")][0].build_num')
echo "$NAME: enterprise version: ${ENTERPRISE_VERSION}"

rm -rf plugins navajo *.zip
mkdir plugins navajo

echo "$NAME: Downloading ZIPs"

curl -L -s "https://${BASE_VERSION}-190362472-gh.circle-artifacts.com/0/dexels-base.tgz" -o navajo/dexels_base.tgz
echo "dexels-base complete"

curl -L -s "https://${NAVAJO_VERSION}-4423334-gh.circle-artifacts.com/0/navajo_p2.zip?circle-token=$CIRCLE_TOKEN&branch=${BRANCH}" -o navajo_p2.zip
echo "navajo complete"

curl -L -s "https://${ENTERPRISE_VERSION}-4423339-gh.circle-artifacts.com/0/enterprise_p2.zip?circle-token=$CIRCLE_TOKEN&branch=${BRANCH}"  -o enterprise_p2.zip
echo "enterprise complete"

echo "$NAME: Extracting ZIPs"

ls *.zip | xargs -I '{}' unzip -o '{}'
rm -rf artifacts.* content.* features* *.index
rm -f plugins/*tipi*
rm *.zip

tar xfz navajo/dexels_base.tgz --directory navajo
rm navajo/dexels_base.tgz

cp plugins/* navajo/bundle/
cp run.sh navajo/

zip -r navajo.zip navajo

echo "$NAME: Building docker image"
docker  build  --build-arg TAG=$TAG  .  -t dexels/nav:latest

if [ -n "$PUSH" ]; then
    echo "$NAME: Pusing docker image to docker hub"
    docker  push  dexels/navajo-container-manual:latest
fi

