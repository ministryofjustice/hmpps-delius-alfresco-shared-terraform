FROM docker.elastic.co/elasticsearch/elasticsearch:5.6.16
USER root
RUN sed -i 's/1000/3999/g' /etc/passwd; \
    sed -i 's/1000/3999/g' /etc/group; \
    bin/elasticsearch-plugin install discovery-ec2; \
    bin/elasticsearch-plugin install repository-s3; \
    sed -e '/^-Xm/s/^/#/g' -i /usr/share/elasticsearch/config/jvm.options; \
    chown -R elasticsearch:elasticsearch /usr/share/elasticsearch

USER elasticsearch

# ENV ES_JAVA_OPTS=-"Xms512m -Xmx512m"
