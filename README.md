# Kafka protocol Erlang library

This is a kafka wire format encode/decode library, not a kafka client.
See https://github.com/klarna/brod for kafka client implementation.

Code generated from org.apache.kafka.common.protocol.Protocol.

## How to generate kafka.bnf
Ensure you have JDK (1.7+) and gradle (2.0+) installed.
Change kafka version in priv/kafka_protocol_bnf/build.gradle if needed.

    make kafka-bnf

## Usage
Set environment variable `KAFKA_PROTOCOL_NO_SNAPPY=1` to compile without 
`snappyer` dependency and have snappy compression/decompression disabled.

