[![kafka_protocol](https://github.com/kafka4beam/kafka_protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/kafka4beam/kafka_protocol/actions/workflows/ci.yml)

# Kafka protocol library for Erlang/Elixir

This library provides:

* Basic kafka connection management APIs
* Kafka protocol wire format encode/decode functions
* Kafka RPC primitives
* Utility functions to help building requests and parsing responses

See [brod](https://github.com/kafka4beam/brod) for a complete kafka client implementation.

## Compression

Since version 4.0, `kafka_protocol` no longer includes compression libraries as dependencies.
You must add your desired dependencies to the wrapping project's rebar or mix config.

| Compression Algorithm | Default Library                                    |
|-----------------------|----------------------------------------------------|
| Snappy                | [snappyer](https://github.com/kafka4beam/snappyer) |
| Lz4                   | [lz4b](https://github.com/kafka4beam/lz4b)         |
| Zstd                  | [zstd](https://github.com/silviucpp/ezstd)         |

### Override default compression dependencies

User may override default compression libs with modules having below APIs implemented:

```
-callback compress(iodata()) -> iodata().
-callback decompress(binary()) -> iodata().
```

There are two approaches to inject such dynamic dependencies to `kakfa_protocol`:

#### Set application environment

e.g. Set `{provide_compression, [{snappy, my_snappy_module}, {lz4, my_lz4_module}, {zstd, my_zstd_module}]}`
in `kafka_protocol` application environment, (or provide from sys.config).

Starting from 4.2, the compression modules are cached in `persistent_term`, which can be overridden by calling `kpro:provide_compression`.

#### Call `kpro:provide_compression`

e.g. `kpro:provide_compression([{snappy, my_snappy_module}, {lz4, my_lz4_module}, {zstd, my_zstd_module}]).`

## Test (`make eunit`)

To make a testing environment locally (requires docker) run `make test-env`.
To test against a specific kafka version (e.g. `0.9`), set environment variable `KAFKA_VERSION`. e.g. `export KAFKA_VERSION=0.9`

To test with an existing kafka cluster set below environment variables:

- `KPRO_TEST_KAFKA_ENDPOINTS`: Comma separated endpoints, e.g. `plaintext://localhost:9092,ssl://localhost:9093,sasl_ssl://localhost:9094,sasl_plaintext://localhost:9095`
- `KPRO_TEST_KAFKA_TOPIC_NAME`: Topic name for message produce/fetch test.
- `KPRO_TEST_KAFKA_TOPIC_LAT_NAME`: Topic name for message produce/fetch test with `message.timestamp.type=LogAppendTime` set.
- `KPRO_TEST_KAFKA_SASL_USER_PASS_FILE`: A text file having two lines for username and password.
- `KPRO_TEST_SSL_KEY_FILE`: Client private key file
- `KPRO_TEST_SSL_CERT_FILE`: Client cert file

## Connecting to kafka 0.9

The `api_versions` API was introduced in kafka `0.10`.
This API can be used to query all API version ranges.
When connecting to kafka, `kpro_connection` would immediately perform an RPC of this API
and cache the version ranges in RPC reply in its looping state.
When connecting to kafka `0.9`, `query_api_versions` config entry should be set to `false`
otherwise the socket will be closed by kafka.

## Schema Explained

The schemas of all API requests and respones can be found in `src/kpro_schema.erl`
which is generated from `priv/kafka.bnf`.

The root level `schema` is always a `struct`.
A `struct` consists of fields having lower level (maybe nested) `schema`

Struct fields are documented in `priv/kafka.bnf` as comments,
but the comments are not generated as Erlang comments in `kpro_schema.erl`

Take `produce` API for example

```
req(produce, V) when V >= 0, V =< 2 ->
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

## Code Generation

Schema code is generated from JAVA class `org.apache.kafka.common.protocol.Protocol`
Generated code are committed to the git repo, there is usually no need to re-generate
the code unless there are changes in code-generation scripts or supporting a new kafka version.

### How to Generate `priv/kafka.bnf`

Ensure you have JDK (1.7+) and gradle (2.0+) installed.
Change kafka version in priv/kafka_protocol_bnf/build.gradle if needed.

```
make kafka-bnf
```

### How to Generate `src/kafka_schema.erl`

```
make gen-code
```
