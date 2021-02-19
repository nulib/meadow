# 26. reentrant-processes

Date: 2020-09-25

## Status

Accepted

## Context

Elixir provides a very high level of fault tolerance and quick restarts of failed processes, but our code has
to be written properly to take advantage of this restart capability. Work Queues are one solution, but not
always feasible (because iterating over and queueing up thousands of tasks can be a long-running operation in 
itself).

## Decision

Avoid writing long-running, iterative operations – especially those that change data – as loops. Rather, 
use a single, atomic initialization task to record tasks to be done (and a way to track completion), and use a 
[`GenServer`](https://hexdocs.pm/elixir/GenServer.html) or [`GenStage`](https://hexdocs.pm/gen_stage/GenStage.html)
to handle the task (and mark it done) in atomic, transactional pieces.

### Pseudocode Pattern

Init (one-time):

```
start transaction
  initialize all task tickets
commit transaction
```

Process (periodic):

```
batch = load n pending task tickets
mark batch tickets as processing
iterate over batch tickets
  start transaction
    process one ticket
    mark ticket as complete
  commit transaction
```

Sweep (periodic):

```
expired = find processing task tickets older than a reasonable timeout
mark expired as pending in a single update
```

## Consequences

- Tasks become more resilient and able to survive a process/server termination, crash, restart,
  or replacement
- Code becomes more complicated as loops needs to be broken out into init/process/sweep stages
