ARG TAG=5.0.0
FROM dexels/navajo-dependency:$TAG
ADD plugins/ /opt/felix/bundle
MAINTAINER Frank Lyaruu
ENTRYPOINT ["/opt/felix/startup.sh"]
