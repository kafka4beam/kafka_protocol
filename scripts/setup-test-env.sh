#!/bin/bash -eu

set -x
docker ps > /dev/null || {
    echo "You must be a member of docker group to run this script"
    exit 1
}

KAFKA_IMAGE_VERSION="${KAFKA_IMAGE_VERSION:-1.1.3}"
VERSION="${KAFKA_VERSION:-${1:-4.1.0}}"

case $VERSION in
  0.10*)
    VERSION="0.10"
    ;;
  0.11*)
    VERSION="0.11"
    ;;
  1.*)
    VERSION="1.1"
    ;;
  2.*)
    VERSION="2.8"
    ;;
  3.*)
    VERSION="3.9"
    ;;
  4.0)
    VERSION="4.0"
    ;;
  4.*)
    VERSION="4.1"
    ;;
  *)
    echo "Unknown version $VERSION"
    exit 1
    ;;
esac

export KAFKA_VERSION=$VERSION
export KAFKA_IMAGE_TAG="zmstone/kafka:${KAFKA_IMAGE_VERSION}-${KAFKA_VERSION}"
echo "Using $KAFKA_IMAGE_TAG"

KAFKA_MAJOR=$(echo "$KAFKA_VERSION" | cut -d. -f1)
if [ "$KAFKA_MAJOR" -lt 3 ]; then
    NEED_ZOOKEEPER=true
else
    NEED_ZOOKEEPER=false
fi

if [[ "$NEED_ZOOKEEPER" = true ]]; then
    BOOTSTRAP_OPTS="--zookeeper localhost:2181"
else
    BOOTSTRAP_OPTS="--bootstrap-server localhost:9092"
fi

TD="$(cd "$(dirname "$0")" && pwd)"

docker compose -f $TD/docker-compose.yml down || true
docker compose -f $TD/docker-compose-kraft.yml down || true

if [[ "$NEED_ZOOKEEPER" = true ]]; then
    docker compose -f $TD/docker-compose.yml up -d
else
    docker compose -f $TD/docker-compose-kraft.yml up -d
fi

# give kafka some time
sleep 5

n=0
while [ "$(docker exec kafka-1 bash -c "/opt/kafka/bin/kafka-topics.sh $BOOTSTRAP_OPTS --list")" != '' ]; do
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
  CMD="/opt/kafka/bin/kafka-topics.sh $BOOTSTRAP_OPTS --create --partitions $PARTITIONS --replication-factor $REPLICAS --topic $TOPIC_NAME --config min.insync.replicas=1 $EXTRA_OPTS"
  docker exec kafka-1 bash -c "$CMD"
}

create_topic "try-to-create-ignore-failure" || true
create_topic "test-topic"

if [[ "$KAFKA_VERSION" != 0.9* ]]; then
  create_topic "test-topic-lat" 1 1 --config message.timestamp.type=LogAppendTime
fi

if [ "$KAFKA_MAJOR" -ge 2 ]; then
  MAYBE_NEW_CONSUMER=""
else
  MAYBE_NEW_CONSUMER="--new-consumer"
fi
# this is to warm-up kafka group coordinator for tests
docker exec kafka-1 /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 $MAYBE_NEW_CONSUMER --group test-group --describe > /dev/null 2>&1 || true

# for kafka 0.11 or later, add sasl-scram test credentials
if [[ "$KAFKA_VERSION" != 0.9* ]] && [[ "$KAFKA_VERSION" != 0.10* ]]; then
  docker exec kafka-1 /opt/kafka/bin/kafka-configs.sh \
    $BOOTSTRAP_OPTS \
    --alter \
    --add-config 'SCRAM-SHA-256=[iterations=8192,password=ecila]' \
    --entity-type users \
    --entity-name alice

  docker exec kafka-1 /opt/kafka/bin/kafka-configs.sh \
    $BOOTSTRAP_OPTS \
    --alter \
    --add-config 'SCRAM-SHA-512=[password=ecila]' \
    --entity-type users \
    --entity-name alice
fi

mkdir -p test/certs
docker cp kafka-1:/localhost-client-crt.pem ./test/certs/client-crt.pem
docker cp kafka-1:/localhost-client-key.pem ./test/certs/client-key.pem
