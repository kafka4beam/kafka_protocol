# Kafka protocol Erlang library

This is a kafka wire format encode/decode library, not a kafka client.
See https://github.com/klarna/brod for kafka client implementation.

Code generated from org.apache.kafka.common.protocol.Protocol.

## How to generate kafka.bnf
Ensure you have java (1.7+) and gradle (2.0+) installed.

Kafka version might be different, path to kafka_protocol might be different. Adjust accordingly.

    git clone https://github.com/apache/kafka.git
    cd kafka
    git apply ~/src//kafka_protocol/priv/kafka-gradle.diff
    gradle
    cp ~/src/kafka_protocol/priv/KafkaProtocolBnf.java clients/src/main/java/org/apache/kafka/common/protocol/
    ./gradlew jar
    java -cp clients/build/libs/kafka-clients-0.10.3.0-SNAPSHOT.jar:core/build/dependant-libs-2.10.6/commons-lang3-3.5.jar org.apache.kafka.common.protocol.KafkaProtocolBnf > ~/src/kafka_protocol/priv/kafka.bnf

## Usage
Set environment variable `KAFKA_PROTOCOL_NO_SNAPPY=1` to compile without 
`snappyer` dependency and have snappy compression/decompression disabled.

