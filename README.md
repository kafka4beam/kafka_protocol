# Kafka protocol library for Erlang/Elixir

This is a kafka wire format encode/decode library, not a kafka client.
See https://github.com/klarna/brod for kafka client implementation.

Code generated from org.apache.kafka.common.protocol.Protocol.

## How to generate priv/kafka.bnf
Ensure you have JDK (1.7+) and gradle (2.0+) installed.
Change kafka version in priv/kafka_protocol_bnf/build.gradle if needed.

    make kafka-bnf

## How to generate src/kafka_schema.erl
    make gen-code

## Schema explained

Take `produce_request` for example

```
get(produce_request, V) when V >= 0, V =< 2 ->
  [{acks,int16},
   {timeout,int32},
   {topic_data,{array,[{topic,string},
                       {data,{array,[{partition,int32},
                                     {record_set,records}]}}]}}];
```

It is generated from below BNF block.

```
ProduceRequestV0 => acks timeout [topic_data]
  acks => INT16
  timeout => INT32
  topic_data => topic [data]
    topic => STRING
    data => partition record_set
      partition => INT32
      record_set => RECORDS
```

The root level `schema` is always a `struct`.

A `struct` consists of fields having lower level `schema`
which can be another `struct`, an `array` or a `primitive`.

## Test (`make eunit`)

To make a testbed localy (requires docker) execut `make testbed`
To test with a existing kafka cluster set below os variables:

- `KPRO_TEST_KAFKA_ENDPOINTS`: Comma separated endpoints, e.g. `plaintext://localhost:9092,ssl://localhost:9093,sasl_ssl://localhost:9094`
- `KPRO_TEST_KAFKA_TOPIC_NAME`: Topic name for message produce/fetch test.
- `KPRO_TEST_KAFKA_SASL_PLAIN_USER_PASS_FILE`: A text file having two lines for username and password.
- `KPRO_TEST_SSL_TRUE`: Set to "TRUE" or 'true' to use `ssl => true' in connection config (if kafka ca is trusted already)
- `KPRO_TEST_SSL_CA_CERT_FILE`: Ca cert file
- `KPRO_TEST_SSL_KEY_FILE`: Client private key file
- `KPRO_TEST_SSL_CERT_FILE`: Client cert file

