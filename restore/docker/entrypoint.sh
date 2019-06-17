#!/bin/bash

JVM_OPTIONS_FILE="/etc/elasticsearch/jvm.options"
JVM_TEMP=jvm_options_temp

echo "
-Xms${ES_JVM_MEM}
-Xmx${ES_JVM_MEM}
" > ${JVM_TEMP}

cat ${JVM_OPTIONS_FILE} >> ${JVM_TEMP}

rm -rf ${JVM_OPTIONS_FILE}

mv ${JVM_TEMP} ${JVM_OPTIONS_FILE}

/opt/elasticsearch/install/bin/elasticsearch