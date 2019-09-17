# DRAFT: Meadow Ingest Pipeline

## Definitions

### Action

A single idempotent unit of work performed on an Object as part of a pipeline. _Examples: Attach FileSet to Work, Create Derivatives, Move Master to Permanent Storage._

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
  - I have been informally referring to this `SQS→SNS→SQS...` message chain as `SQNS`, pronounced “sequins” or “sequence.”

An `Action` that has multiple prerequisites (e.g., two different) `Actions` or multiple iterations of another `Action` might require an intermediate `Action` that waits for and collects all of its dependency `Messages` before completing.
