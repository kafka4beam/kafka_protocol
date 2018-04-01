FROM java:openjdk-8-jre

ARG VERSION
ARG DOWNLOAD_URL_PREFIX

ENV SCALA_VERSION 2.11

ENV KAFKA_VERSION $VERSION
ENV KAFKA_DOWNLOAD_URL $DOWNLOAD_URL_PREFIX/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

RUN apt-get update && \
    apt-get install -y zookeeper wget supervisor dnsutils && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    wget -q "${KAFKA_DOWNLOAD_URL}" -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    ln -s /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION" /opt/kafka && \
    mkdir -p /etc/kafka

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY server.properties /etc/kafka/server.properties
COPY server.jks /etc/kafka/server.jks
COPY truststore.jks /etc/kafka/truststore.jks
COPY jaas.conf /etc/kafka/jaas.conf
#COPY log4j.properties /opt/kafka/config/log4j.properties

ENTRYPOINT ["/docker-entrypoint.sh"]

## run kafka by default, 'run zookeeper' to start zookeeper instead
CMD ["run", "kafka"]

