# Meadow Ingest Pipeline

## Definitions

### Action

A single idempotent unit of work performed on an Object as part of a pipeline. _Examples: Attach FileSet to Work, Create Derivatives, Move File to Permanent Storage._

Every Action has three pieces:

- A `Queue` that delivers a `Message` to a →
- `Worker` that performs the work indicated by the `Message` and sends a new/updated `Message` to a →
- `Topic`

### Message

The information required to kick off a specific `Action`.

### Object

Any persistent combination of data and metadata handled by an ingest pipeline. _Examples: Work, FileSet_

### Pipeline

The entire ingest process for a specific type of `Object`.

### Queue

A broker that holds `Messages` until polled, ensuring that every `Message` is delivered _at least_ once, and which can retry them on failure or timeout. Every `Message` is expected to be received and handled by a single `Worker`.

### Topic

A broker that receives `Messages` and sends out notifications. The main difference between a `Queue` and a `Topic` is that a `Queue` waits to be polled and delivers `Messages` to a single handler, while a `Topic` pushes notifications out immediately to any number of subscribers. Every possible end state for a particular `Action` (e.g., success/failure) will have its own `Topic`.

### Worker

The code that actually performs the unit of work required by an `Action`.

## Implementation Details

- `Queues` are [AWS SQS](https://aws.amazon.com/sqs/) Queues.
- `Topics` are [AWS SNS](https://aws.amazon.com/sns/) Topics.
- Workers are our code, written in anything that can receive from a `Queue` and send to a `Topic`.
  - Most `Workers` will be written in Elixir using [Broadway](https://hexdocs.pm/broadway/), with [BroadwaySQS](https://hexdocs.pm/broadway_sqs/) as the producer and a custom batcher that delivers processed messages to SNS.
  - Some `Workers` might be implemented in other languages if they are better suited to the work. For example, image derivatives are best  created using VIPS via Sharp, which requires a nodejs `Worker`.
- `Actions` are chained together into `Pipelines` by having `Queues` subscribe to `Topics`. It is also possible to have an AWS Lambda subscribe to a `Topic` in order to start a non-Elixir worker or perform other housekeeping tasks outside the scope of `Workers`.
  - This `SQS→SNS→SQS...` message chain pattern has been extracted into a Hex package called `Sequins`.

An `Action` that has multiple prerequisites (e.g., two different) `Actions` or multiple iterations of another `Action` might require an intermediate `Action` that waits for and collects all of its dependency `Messages` before completing.

### Characteristics of Actions

1. `Actions` are *deterministic*. Given the same input, an `Action` will always provide the same output.
2. `Actions` are *referentially opaque*. This is just a fancy way of saying that `Actions` might (and usually will) have side effects. In some cases, the side effects are the whole point.
3. `Actions` are *idempotent*. An Action will always check to see if its work has already been done, and will not do it again. Any work that does get repeated results in the same output and side effects (i.e., no duplications, no appending multiple copies of things).
4. The input to any `Action` can be condensed and expressed as a single binary value. E.g., Row `2` of Ingest Sheet `01DMKFWMA7VTV960MSMWAHJ0FX` can be expressed as `01DMKFWMA7VTV960MSMWAHJ0FX:2`.
