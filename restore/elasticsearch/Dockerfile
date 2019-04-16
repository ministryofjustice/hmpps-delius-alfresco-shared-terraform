FROM java:8

ARG ES_HOME_DIR=/opt/elasticsearch

RUN groupadd elasticsearch \
    && useradd -m -d ${ES_HOME_DIR} -g elasticsearch elasticsearch \
    && mkdir -p ${ES_HOME_DIR}/data ${ES_HOME_DIR}/logs ${ES_HOME_DIR}/install /etc/elasticsearch \
    && chown -R elasticsearch:elasticsearch ${ES_HOME_DIR}/data ${ES_HOME_DIR}/logs ${ES_HOME_DIR}/install /etc/elasticsearch

USER elasticsearch

RUN curl -L -o /tmp/elasticsearch.tar.gz \
    https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.4.6/elasticsearch-2.4.6.tar.gz

RUN tar xvzf /tmp/elasticsearch.tar.gz -C ${ES_HOME_DIR}/install --strip-components=1

RUN mv ${ES_HOME_DIR}/install/config/logging.yml /etc/elasticsearch/

RUN rm -rf /tmp/elasticsearch.tar.gz ${ES_HOME_DIR}/install/config

RUN ln -sf /etc/elasticsearch /opt/elasticsearch/install/config

WORKDIR ${ES_HOME_DIR}

EXPOSE 9200 9300

ADD ./elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

VOLUME [ "/opt/elasticsearch/data", "/opt/elasticsearch/logs"]

CMD [ "/opt/elasticsearch/install/bin/elasticsearch" ]