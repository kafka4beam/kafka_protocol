#!/bin/bash -ex

cd $(dirname "$0")

# test against 1.1.0 by default
VERSION="${1:-1.1.0}"

case $VERSION in
  0.9)
    VERSION="0.9.0.0";;
  0.10)
    VERSION="0.10.2.1";;
  0.11)
    VERSION="0.11.0.2";;
  1.*)
    VERSION="1.1.0";;
  *)
    true
esac

case $VERSION in
  0.9*)
    DOWNLOAD_URL_PREFIX="https://archive.apache.org/dist/kafka";;
  *)
    DOWNLOAD_URL_PREFIX="https://apache.org/dist/kafka/";;
esac

IMAGE="kafka_protocol_test:${VERSION}"
sudo docker build --build-arg VERSION=$VERSION --build-arg DOWNLOAD_URL_PREFIX=$DOWNLOAD_URL_PREFIX -t $IMAGE .

ZK='zookeeper'
KAFKA_1='kafka-1'
CONTAINERS="$ZK $KAFKA_1"

# kill running containers
for i in $CONTAINERS; do sudo docker rm -f $i > /dev/null 2>&1 || true; done

sudo docker run -d \
                -p 2181:2181 \
                --name $ZK \
                $IMAGE run zookeeper

n=0
while [ "$(</dev/tcp/localhost/2181 2>/dev/null && echo OK || echo NOK)" = "NOK" ]; do
  if [ $n -gt 4 ]; then
    echo "timeout waiting for $ZK"
    exit 1
  fi
  n=$(( n + 1 ))
  sleep 1
done

sudo docker run -d \
                -e BROKER_ID=0 \
                -e PLAINTEXT_PORT=9092 \
                -e SSL_PORT=9093 \
                -e SASL_SSL_PORT=9094 \
                -p 9092:9092 \
                -p 9093:9093 \
                -p 9094:9094 \
                --link $ZK \
                --name $KAFKA_1 \
                $IMAGE run kafka

n=0
while [ "$(sudo docker exec $KAFKA_1 bash -c '/opt/kafka/bin/kafka-topics.sh --zookeeper zookeeper --describe')" != '' ]; do
  if [ $n -gt 4 ]; then
    echo "timeout waiting for $KAFKA_1"
    exit 1
  fi
  n=$(( n + 1 ))
  sleep 1
done

create_topic() {
  TOPIC_NAME="$1"
  PARTITIONS="${2:-1}"
  REPLICAS="${3:-1}"
  CMD="/opt/kafka/bin/kafka-topics.sh --zookeeper zookeeper --create --partitions $PARTITIONS --replication-factor $REPLICAS --topic $TOPIC_NAME"
  sudo docker exec $KAFKA_1 bash -c "$CMD"
}

create_topic "try-to-create-ignore-failure" || true
create_topic "test-topic"

# this is to warm-up kafka group coordinator for deterministic in tests
sudo docker exec $KAFKA_1 /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --new-consumer --group test-group --describe > /dev/null 2>&1

