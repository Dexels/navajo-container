#!/bin/bash
export flag="-Dfile.encoding=UTF-8 -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:NativeMemoryTracking=summary -XX:+PrintNMTStatistics"
# Set UseCGroupMemoryLimitForHeap options if required
if [ ! -z "$GCTHREADSSIZE" ] && [[ $GCTHREADSSIZE =~ ^-?[0-9]+$ ]]; then
  flag+=" -XX:ParallelGCThreads=$GCTHREADSSIZE"
else
  flag+=" -XX:ParallelGCThreads=1"
fi
if [ ! -z "$httpProxyHost" ]; then
  export httpProxyURL="http://${httpProxyHost}:${httpProxyPort}"
  export flag+=" -Dhttp.proxyHost=${httpProxyHost} -Dhttp_proxy=${httpProxyURL} -Dhttp.proxyPort=${httpProxyPort} -Dhttps.proxyPort=${httpProxyPort} -Dhttps.proxyHost=${httpProxyHost}";
  if [ ! -z "$nonProxyHosts"]; then
    export flag+= " -DnonProxyHosts=${nonProxyHosts}"
  fi
fi
if [ ! -z "$httpClientDebug" ]; then
  flag+=" -Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.SimpleLog"
  flag+=" -Dorg.apache.commons.logging.simplelog.showdatetime=true"
  flag+=" -Dorg.apache.commons.logging.simplelog.log.org.apache.http=DEBUG"
  flag+=" -Dorg.apache.commons.logging.simplelog.log.org.apache.http.wire=ERROR"
fi
# Set debug options if required
if [ ! -z "$JAVA_ENABLE_DEBUG" ] && [ "$JAVA_ENABLE_DEBUG" != "false" ]; then
    flag+=" -Dcom.sun.management.jmxremote"
    flag+=" -Dcom.sun.management.jmxremote.authenticate=false"
    flag+=" -Dcom.sun.management.jmxremote.ssl=false"
    flag+=" -Dcom.sun.management.jmxremote.local.only=false"
    flag+=" -Dcom.sun.management.jmxremote.port=1099"
    flag+=" -Dcom.sun.management.jmxremote.rmi.port=1099"
    flag+=" -Djava.rmi.server.hostname=127.0.0.1"
fi
if [ -z "$LOGLEVEL" ]; then
  export LOGLEVEL=INFO
fi
if [ ! -z "$startflags" ]; then
  flag+=" $startflags"
fi
if [ -z "$LOGAPPENDERS" ]; then
  export LOGAPPENDERS=out
fi
if [ -z "$INTERACTIVE" ]; then
  export NONINTERACTIVE='-Dgosh.args=--nointeractive'
else
  export NONINTERACTIVE=''
fi
# TODO: before startup clean all the chached and compiled scripts in this volume, so that kube restarts act correctly
if [ -z "$FILE_REPOSITORY_PATH" ]; then
  echo "Clearing before startup..."
  rm -rf /storage/*
else
  echo "Detected FILE_REPOSITORY_PATH, so not deleting storage"
fi

rm -rf felix/felix-cache/*
echo "Startup flags: ${flag} LOGLEVEL: ${LOGLEVEL} LOGAPPENDERS: ${LOGAPPENDERS} FELIX_OPTS: ${FELIX_OPTS}"
exec java -DLOGLEVEL=${LOGLEVEL} -DLOGAPPENDERS=${LOGAPPENDERS} ${FELIX_OPTS} ${NONINTERACTIVE} -Dmvncache=mvncache  ${flag} -jar bin/felix.jar
