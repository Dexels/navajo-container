#!/bin/bash
rm -rf felix-cache
export INTERACTIVE=true
export FILE_REPOSITORY_PATH=$1
export FILE_REPOSITORY_STORAGE=./tmp
export FILE_REPOSITORY_TYPE=multitenant
export FILE_REPOSITORY_DEPLOYMENT=develop
export FILE_REPOSITORY_MONITORED=config
export FILE_REPOSITORY_FILEINSTALL=config
export HAZELCAST_SIMPLE=true

# returns the JDK version.
# 8 for 1.8.0_nn, 9 for 9-ea etc, and "no_java" for undetected
jdk_version() {
  local result
  local java_cmd
  if [[ -n $(type -p java) ]]
  then
    java_cmd=java
  elif [[ (-n "$JAVA_HOME") && (-x "$JAVA_HOME/bin/java") ]]
  then
    java_cmd="$JAVA_HOME/bin/java"
  fi
  local IFS=$'\n'
  # remove \r for Cygwin
  local lines=$("$java_cmd" -Xms32M -Xmx32M -version 2>&1 | tr '\r' '\n')
  if [[ -z $java_cmd ]]
  then
    result=no_java
  else
    for line in $lines; do
      if [[ (-z $result) && ($line = *"version \""*) ]]
      then
        local ver=$(echo $line | sed -e 's/.*version "\(.*\)"\(.*\)/\1/; 1q')
        # on macOS, sed doesn't support '?'
        if [[ $ver = "1."* ]]
        then
          result=$(echo $ver | sed -e 's/1\.\([0-9]*\)\(.*\)/\1/; 1q')
        else
          result=$(echo $ver | sed -e 's/\([0-9]*\)\(.*\)/\1/; 1q')
        fi
      fi
    done
  fi
  echo "$result"
}
java_version="$(jdk_version)"
if [ "$java_version" -lt "11" ]
then
  echo "newer java required"
  exit
fi
echo $v

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
  export LOGAPPENDERS=stdout
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
echo "A: $NONINTERACTIVE"
echo "Startup flags: ${flag} LOGLEVEL: ${LOGLEVEL} LOGAPPENDERS: ${LOGAPPENDERS} FELIX_OPTS: ${FELIX_OPTS}"
java -DLOGLEVEL=${LOGLEVEL} -DLOGAPPENDERS=${LOGAPPENDERS} ${FELIX_OPTS} ${NONINTERACTIVE} -Dmvncache=mvncache  ${flag} -jar bin/felix.jar
