#!/bin/bash -eu

docker ps > /dev/null || {
    echo "You must be a member of docker group to run this script"
    exit 1
}

VERSION=${KAFKA_VERSION:-2.4}
if [ -z $VERSION ]; then VERSION=$1; fi

case $VERSION in
  0.10*)
    VERSION="0.10";;
  0.11*)
    VERSION="0.11";;
  1.*)
    VERSION="1.1";;
  2.*)
    VERSION="2.4";;
  *)
    VERSION="2.4";;
esac

echo "Using KAFKA_VERSION=$VERSION"
export KAFKA_VERSION=$VERSION

TD="$(cd "$(dirname "$0")" && pwd)"

docker compose -f $TD/docker-compose.yml down || true
docker compose -f $TD/docker-compose.yml up -d

# give kafka some time
sleep 5

n=0
while [ "$(docker exec kafka-1 bash -c '/opt/kafka/bin/kafka-topics.sh --zookeeper localhost --list')" != '' ]; do
  if [ $n -gt 4 ]; then
    echo "timeout waiting for kakfa_1"
    exit 1
  fi
  n=$(( n + 1 ))
  sleep 1
done

function create_topic {
  TOPIC_NAME="$1"
  PARTITIONS="${2:-1}"
  REPLICAS="${3:-1}"
  EXTRA_OPTS="${*:2}"
  CMD="/opt/kafka/bin/kafka-topics.sh --zookeeper localhost --create --partitions $PARTITIONS --replication-factor $REPLICAS --topic $TOPIC_NAME --config min.insync.replicas=1 $EXTRA_OPTS"
  docker exec kafka-1 bash -c "$CMD"
}

create_topic "try-to-create-ignore-failure" || true
create_topic "test-topic"

if [[ "$KAFKA_VERSION" != 0.9* ]]; then
  create_topic "test-topic-lat" 1 1 --config message.timestamp.type=LogAppendTime
fi

if [[ "$KAFKA_VERSION" = 2* ]]; then
  MAYBE_NEW_CONSUMER=""
else
  MAYBE_NEW_CONSUMER="--new-consumer"
fi
# this is to warm-up kafka group coordinator for deterministic in tests
docker exec kafka-1 /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 $MAYBE_NEW_CONSUMER --group test-group --describe > /dev/null 2>&1

# for kafka 0.11 or later, add sasl-scram test credentials
if [[ "$KAFKA_VERSION" != 0.9* ]] && [[ "$KAFKA_VERSION" != 0.10* ]]; then
  docker exec kafka-1 /opt/kafka/bin/kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=ecila],SCRAM-SHA-512=[password=ecila]' --entity-type users --entity-name alice
fi
