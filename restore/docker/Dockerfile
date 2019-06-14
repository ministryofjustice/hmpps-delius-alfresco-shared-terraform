FROM java:8

ARG ES_HOME_DIR=/opt/elasticsearch
ARG ES_VERSION=5.6.16

RUN groupadd -g 3999 elasticsearch \
    && useradd -m -d ${ES_HOME_DIR} -u 3999 -g elasticsearch elasticsearch \
    && mkdir -p ${ES_HOME_DIR}/data ${ES_HOME_DIR}/logs ${ES_HOME_DIR}/install /etc/elasticsearch /opt/es_backup /opt/local \
    && chown -R elasticsearch:elasticsearch ${ES_HOME_DIR}/data ${ES_HOME_DIR}/logs ${ES_HOME_DIR}/install /etc/elasticsearch /opt/es_backup /opt/local

USER elasticsearch

RUN curl -L -o /tmp/elasticsearch.tar.gz \
    https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz

RUN tar xvzf /tmp/elasticsearch.tar.gz -C ${ES_HOME_DIR}/install --strip-components=1

RUN mv ${ES_HOME_DIR}/install/config/jvm.options /etc/elasticsearch/

RUN mv ${ES_HOME_DIR}/install/config/log4j2.properties /etc/elasticsearch/

RUN rm -rf /tmp/elasticsearch.tar.gz ${ES_HOME_DIR}/install/config

RUN ln -sf /etc/elasticsearch /opt/elasticsearch/install/config

WORKDIR ${ES_HOME_DIR}

EXPOSE 9200 9300

ADD ./elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

VOLUME [ "/opt/elasticsearch/data", "/opt/elasticsearch/logs"]

CMD [ "/opt/elasticsearch/install/bin/elasticsearch" ]