# Kafka protocol Erlang library

Code generated from BNF definitions https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol

Set environment variable `KAFKA_PROTOCOL_NO_SNAPPY=1` to compile without 
`snappyer` dependency and have snappy compression/decompression disabled.

This is a kafka wire format encode/decode library, not a kafka client.
See https://github.com/klarna/brod for kafka client implementation.

