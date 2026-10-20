# Metrics

Meadow emits fine-grained `:telemetry` events, accumulates them in memory, and flushes
aggregates to CloudWatch once a minute. Nothing is published per event.

Two namespaces split the work by what each is *about*, not by what it touches:

- **`Meadow.Telemetry`** is the `:telemetry` side — attaching handlers, re-emitting
  Absinthe events, and describing everything for Live Dashboard. It would still make
  sense if CloudWatch did not exist.
- **`Meadow.Metrics`** is everything that exists *because* CloudWatch does — the
  accumulator, the bucketing, the publishers, the boot-time confirmation.

Measurements flow one way, so `Meadow.Metrics` never needs to know what a telemetry
event is:

```
your code
    |
    |  :telemetry.span / :telemetry.execute
    v
[:meadow, ...] event ------------------------> Meadow.Telemetry.metrics/0
    |                                              |
    |  Meadow.Telemetry.Handlers                   v
    v                                          Live Dashboard (sampled, kept nowhere)
Meadow.Metrics.Aggregator  (public ETS, atomic counters)
    |
    |  every 60s, aligned to the minute
    v
Meadow.Metrics.Publisher  ->  CloudWatch | Logger | nil
```

## What is tracked today

| Metric | Instrument | Dimensions | Emitted from |
| --- | --- | --- | --- |
| `pipeline.action.duration` | histogram (ms) | `Action` | span around each action's own `process/2` |
| `pipeline.action.count` | counter | `Action`, `Outcome` | the same span, plus the skip event |
| `pipeline.action.exception` | counter | `Action`, `Kind` | the span's `exception` event |
| `pipeline.transcode.duration` | histogram (ms) | `MediaType` | `TranscodeComplete`, measured against the start time MediaConvert echoes back |
| `pipeline.transcode.count` | counter | `MediaType`, `Outcome` | the same event |
| `pipeline.transcode.stalled` | gauge | none | sampled each flush by `Meadow.Metrics.Probes` |
| `pipeline.file_set.duration` | histogram (ms) | `Role`, `MediaType` | `FileSetComplete`, measured from pipeline kickoff |

`Outcome` is one of `ok`, `error`, `skip`, `retry`, or `unknown`. `MediaType` is bucketed
to `audio`, `video`, `image` or `other` — never a full mime type.

Some things deliberately have **no** metric here:

- **SQS queue depth.** `AWS/SQS` already publishes
  `ApproximateNumberOfMessagesVisible` and `ApproximateAgeOfOldestMessage` for free.
  The second is the better backlog signal: depth can read low while one message retries
  in a loop.
- **Lambda duration** for the Lambda-backed actions. `AWS/Lambda` covers it; the action
  duration here is that plus Meadow-side overhead, which is the interesting delta.
- **Absinthe operations.** Still re-emitted by `Meadow.Telemetry.GraphQL` for Live
  Dashboard, but not routed to CloudWatch — dimensioning by field name across the schema
  would mint a metric per root field, most of them near-empty.

### Only some actions are timed

`pipeline.action.*` is published only for the actions listed in `metrics[:actions]`
(`app/lib/meadow/config/runtime.ex`). The dispatch and completion bookkeeping actions are
left off because their timings are noise next to the actions that do real work.

`pipeline.file_set.duration` is emitted **outside** that check on purpose, since
`FileSetComplete` is not on the list and the end-to-end measurement would otherwise never
fire. There is a test asserting this, so it does not get "tidied" inside the condition.

## Configuration

All under `config :meadow, metrics: [...]`, which is deep-merged by
`Meadow.Config.Helper.config/2`, so `prod.ex` adding `publisher:` keeps the `actions:`
list from `runtime.ex`.

| Key | Meaning |
| --- | --- |
| `metrics[:actions]` | Action names (last module segment) whose timings are published |
| `metrics[:publisher]` | `Meadow.Metrics.CloudWatch`, `Meadow.Metrics.Logger`, or `nil` to aggregate without sending |
| `:cloudwatch_namespace` | Overrides the derived namespace outright |
| `:cloudwatch_deployed_tenants` | Tenants that share the bare `Meadow` namespace (default `meadow`, `staging`) |
| `:transcode_stalled_after` | How long before an unfinished transcode counts as stalled (default 1h) |
| `:metrics_probes` | The probe functions run each flush; set to `[]` in tests |

### Namespaces

Staging and production are in separate AWS accounts and deliberately **share** the bare
`Meadow` namespace, which keeps a dashboard or alarm portable between them. Every other
tenant gets its own:

```
production (MEADOW_TENANT=meadow)  -> "Meadow"
staging    (MEADOW_TENANT=staging) -> "Meadow"       # separate account
a dev box  (MEADOW_TENANT=mbk)     -> "Meadow/mbk"
```

Developer environments share an account with staging, so this is what stops a dev box
landing on staging's metric names. The task role in `infrastructure/deploy/ecs.tf`
allows `cloudwatch:PutMetricData` only for the bare namespace — note that
`PutMetricData` takes no resource-level permissions, so the `cloudwatch:namespace`
condition key is what scopes it, with `Resource = ["*"]`.

### Publishing outside production

`Meadow.Metrics.Confirmation` runs during `Meadow.Application.start/2`. If the publisher
is `Meadow.Metrics.CloudWatch` and the environment is not `:prod` or `:test`, it requires
`MEADOW_CLOUDWATCH_CONFIRM` to be `yes`, `true`, or `1`; otherwise it logs loudly, clears
the publisher and lets startup continue. A dev box cannot start billing metrics by
inheriting a config line.

## Adding a metric

### 1. Pick the instrument

| You want | Use | Published as |
| --- | --- | --- |
| How many times something happened | `Aggregator.count/3` | `Value` with `Unit: "Count"` |
| How long something took | `Aggregator.observe/3` | `Values`/`Counts` with `Unit: "Milliseconds"` |
| How many of something there are right now | `Aggregator.gauge/4` | `Value`, republished every flush until replaced |

Durations go through `observe/3` rather than a statistic set because **CloudWatch cannot
derive percentiles from a statistic set**. `observe/3` buckets by √2 and publishes
`Values`/`Counts`, which supports percentiles, bounds the error at about 41%, and costs
nothing extra — a whole histogram travels as one metric however many buckets it spans.
Fifty buckets span 1ms to roughly 4.6 hours.

### 2. Emit a telemetry event

For something with a start and an end, use a span. For a point-in-time fact, use
`execute`:

```elixir
:telemetry.execute(
  [:meadow, :ingest, :sheet, :complete],
  %{duration_ms: elapsed, row_count: rows},
  %{status: "ok"}
)
```

Conventions worth following:

- **Measurements are numbers; metadata is context.** Anything that becomes a dimension
  belongs in metadata.
- **Name the unit when it is not native.** `:telemetry.span/3` reports `:duration` in
  native units; a wall-clock difference you computed yourself is not native, so call it
  `:duration_ms` so nobody converts it twice.
- **Classify dimension values at emit time**, the way `Handlers.file_set_dimensions/1`
  does, so the handler receives `"video"` rather than `"video/mp4"`.

### 3. Handle it

Add the event to `@events` in `Meadow.Telemetry.Handlers` and write a clause:

```elixir
def handle_event([:meadow, :ingest, :sheet, :complete], measurements, metadata, _config) do
  Aggregator.observe("ingest.sheet.duration", measurements.duration_ms,
    Status: metadata[:status] || "unknown"
  )

  Aggregator.count("ingest.sheet.rows", measurements.row_count,
    Status: metadata[:status] || "unknown"
  )
rescue
  exception -> warn(:sheet_complete, exception)
end
```

The `rescue` is not optional. **`:telemetry` permanently detaches any handler that
raises**, so one malformed event would take out every pipeline metric until the next
restart, with a single log line to show for it.

`attach/0` is called from `Meadow.Telemetry.init/1` and detaches first, so a supervisor
restart re-attaches cleanly. Adding to `@events` is all that is needed.

### 4. Add it to Live Dashboard, if useful

Live Dashboard reads `Meadow.Telemetry.metrics/0` and consumes the raw event, not the
aggregator, so the metric name there is the **event path plus the measurement key**:

```elixir
summary("meadow.ingest.sheet.complete.duration_ms",
  tags: [:status],
  unit: :millisecond
)
```

Tags must match the metadata keys exactly. A mismatch silently drops the metric.

### 5. Measuring an absence

Some things cannot be measured by an event, because what you care about is the event
*not* arriving — a MediaConvert job that fails without a state change produces no
`TranscodeComplete` at all, so it can never appear in the duration histogram. Those need
a query, run once per flush. Add it to `Meadow.Metrics.Probes.run/0`:

```elixir
def run do
  report_while_nonzero("pipeline.transcode.stalled", stalled_transcodes())
  report_while_nonzero("ingest.sheets.stuck", stuck_sheets())
  :ok
end
```

Use `report_while_nonzero/2` for a count that is usually zero. Gauges are republished
every flush until overwritten, so a probe that simply writes nothing when its count
returns to zero would pin the metric at its last non-zero value forever — the recovery
never appears and an alarm never clears. `report_while_nonzero/2` publishes the drop
once and then retires the gauge.

### 6. Test it

Three levels, and the middle one is the one that catches real bugs:

```elixir
# Handler translation: emit the event, read the aggregator.
:telemetry.execute([:meadow, :ingest, :sheet, :complete], %{duration_ms: 500}, %{status: "ok"})
assert %{"Value" => _} = Enum.find(Aggregator.preview(), &(&1["MetricName"] == "ingest.sheet.rows"))

# Through the real flush, when ordering matters (probes run before gauges are read).
assert %{"Value" => 4} = Aggregator.flush().metric_data |> Enum.find(...)

# End to end, asserting dimension VALUES, not just that the metric exists.
assert dimensions(datum) == %{"Status" => "ok"}
```

Assert dimension *values*. A metric whose dimensions are all `"unknown"` still has the
right name and still passes a test that only checks the name — that exact gap hid a bug
where every action was tagged `"unknown"`.

In tests, set `:metrics_probes` to `[]` so a flush does not hit the database, and pin
`metrics[:actions]` explicitly rather than depending on whatever the runtime config
lists.

## Rules that matter

**Dimension values must be bounded.** A metric is billed per namespace + name +
dimension-value combination. An unbounded value — a file set id, a full mime type, an
error message — mints a metric per distinct value. `Action` (~12) and `Outcome` (~5) are
deliberately small.

**Never add a node or host dimension.** CloudWatch merges datapoints sharing a name,
dimension set and period, so each node publishes its own aggregate and the totals come
out globally correct with no coordination. A node dimension multiplies the billed metric
count by the task count and gives up that free merge.

**`:telemetry.span/3` hands the stop event only what the span function returns.** The
start metadata is *not* merged in — though it is for the `exception` event, which makes
the asymmetry easy to miss. Name everything the handler needs in the stop metadata:

```elixir
metadata = span_metadata(action, data)

:telemetry.span([:meadow, :pipeline, :action], metadata, fn ->
  {action.process(data, attrs), Map.put(metadata, :outcome, outcome(result))}
end)
```

Getting this wrong does not fail loudly: the metric still publishes, tagged `"unknown"`.

**CloudWatch does not aggregate across dimension values.** Querying
`pipeline.action.duration` without an `Action` returns nothing at all — dimensions are
part of a metric's identity, not a filter. Use a `SEARCH()` expression for cross-action
totals rather than publishing a roll-up metric.

**Metrics cannot be deleted.** One stops being billed as soon as it stops receiving
data, but stays visible in `ListMetrics` for 15 months. A one-off error outcome leaves a
permanent ghost series in dashboards.

## Cost

$0.30 per custom metric per month for the first 10,000, prorated hourly and metered only
in the hours a metric actually receives data. So:

| | |
| --- | --- |
| One write, never again | ~$0.0004, once |
| An 8-hour dev session, ~80 metrics | ~$0.26 |
| Left publishing continuously, ~80 metrics | ~$24/month |

`PutMetricData` calls fall under CloudWatch's always-free 1M API requests; one flush per
minute is ~43,000/month per node.

## Inspecting what is collected

```elixir
Meadow.Metrics.preview()      # what the next flush would publish, non-destructively
Meadow.Metrics.last_report()  # the last batch, and whether it was actually published
Meadow.Metrics.flush()        # flush now instead of waiting for the cycle
Meadow.Metrics.namespace()    # where it would go
Meadow.Metrics.publisher()    # nil, Logger, or CloudWatch
```

`Meadow.Metrics.Logger` as the publisher logs each batch instead of sending it, which is
the easiest way to see real metric data without an AWS round trip.
