# Metrics

Meadow emits fine-grained `:telemetry` events. `TelemetryMetricsCloudwatch` accumulates
them in memory and pushes aggregates to CloudWatch at least once a minute. Nothing is
published per event.

Two namespaces split the work by what each is *about*, not by what it touches:

- **`Meadow.Telemetry`** is the `:telemetry` side. It owns every metric definition and
  the handlers that transform events. It would still make sense if CloudWatch did not
  exist.
- **`Meadow.Metrics`** is delivery — which namespace to publish under, whether this node
  may publish, and the reporter's supervision.

```
your code
    |
    |  :telemetry.span / :telemetry.execute
    v
[:meadow, ...] event
    |
    |  Meadow.Telemetry.metrics/0 -----------> Live Dashboard (sampled, kept nowhere)
    |
    |  Meadow.Telemetry.cloudwatch_metrics/0
    v
TelemetryMetricsCloudwatch (attaches itself, accumulates in GenServer state)
    |
    |  at least every push_interval
    v
CloudWatch, or a dry-run log line
```

The reporter attaches itself to whatever the definitions name, so **most new metrics need
no handler at all**.

## What is tracked today

| CloudWatch metric | Type | Dimensions | Event |
| --- | --- | --- | --- |
| `pipeline.action.duration.summary` | Summary (ms) | `action` | `[:meadow, :pipeline, :action, :stop]` |
| `pipeline.action.count.count` | Counter | `action`, `outcome` | the stop and skip events |
| `pipeline.action.exception.count` | Counter | `action`, `kind` | `[..., :action, :exception]` |
| `pipeline.transcode.duration.summary` | Summary (ms) | `media_type` | `[..., :transcode, :complete]` |
| `pipeline.transcode.count.count` | Counter | `media_type`, `outcome` | the same event |
| `pipeline.transcode.stalled.last_value` | LastValue | none | `[..., :transcode, :stalled]`, sampled |
| `pipeline.file_set.duration.summary` | Summary (ms) | `role`, `media_type` | `[..., :file_set, :complete]` |

The reporter appends a type suffix to every CloudWatch metric name, which is why they all
end in `.summary`, `.count` or `.last_value`. The names are declared explicitly rather
than derived from the event path so the suffix lands on something readable.

`outcome` is one of `ok`, `error`, `skip`, `retry`. `media_type` is bucketed to `audio`,
`video`, `image` or `other` — never a full mime type.

Deliberately absent:

- **SQS queue depth.** `AWS/SQS` already publishes `ApproximateNumberOfMessagesVisible`
  and `ApproximateAgeOfOldestMessage` for free. The second is the better backlog signal:
  depth can read low while one message retries in a loop.
- **Lambda duration** for the Lambda-backed actions. `AWS/Lambda` covers it; the action
  duration here is that plus Meadow-side overhead, which is the interesting delta.
- **Absinthe operations.** In `metrics/0` for Live Dashboard, but not in
  `cloudwatch_metrics/0` — dimensioning by field name across the schema would mint a
  metric per GraphQL root field, most of them near-empty.

### Only some actions are timed

The action metrics carry `keep: &Meadow.Telemetry.publish_action?/1`, which drops any
action not listed in `metrics[:actions]` before it reaches either consumer. The dispatch
and completion bookkeeping actions are left off because their timings are noise next to
the actions that do real work.

`pipeline.file_set.duration` is a different event with no `keep`, so it is unaffected —
which matters, because `FileSetComplete` is not on the list and the end-to-end
measurement would otherwise never fire.

## Configuration

Under `config :meadow, metrics: [...]`, deep-merged by `Meadow.Config.Helper.config/2`.

| Key | Meaning |
| --- | --- |
| `metrics[:actions]` | Action names (last module segment) whose timings are published |
| `metrics[:enabled]` | Whether the reporter runs at all. Defaults to off in `:test` |
| `metrics[:push_interval]` | How often to push, in ms. Default 1 minute |
| `:cloudwatch_namespace` | Overrides the derived namespace outright |
| `:cloudwatch_deployed_tenants` | Tenants sharing the bare `Meadow` namespace (default `meadow`, `staging`) |
| `:transcode_stalled_after` | How long before an unfinished transcode counts as stalled (default 1h) |

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
landing on staging's metric names. The task role in `infrastructure/deploy/ecs.tf` allows
`cloudwatch:PutMetricData` only for the bare namespace — `PutMetricData` takes no
resource-level permissions, so the `cloudwatch:namespace` condition key is what scopes
it, with `Resource = ["*"]`.

### Dry runs, and local inspection

Outside production the reporter starts in **dry-run mode** unless
`MEADOW_CLOUDWATCH_CONFIRM` is `yes`, `true` or `1`. Aggregation still happens and each
batch is logged, but nothing is sent and nothing is billed. That is the local inspection
path: real metric data, no AWS round trip.

```elixir
Meadow.Metrics.pending()    # the metric data the next push would send
Meadow.Metrics.flush()      # push now instead of waiting
Meadow.Metrics.namespace()  # where it would go
```

`pending/0` reads the reporter's state and runs the same transformation the push does.
`Cache.pop_metrics/1` is pure — it returns a new cache rather than mutating the running
one — so this is a genuine preview rather than a destructive read.

## Adding a metric

### 1. Declare it

Add a `Telemetry.Metrics` definition to `pipeline_metrics/0` in `Meadow.Telemetry`. Both
consumers read from there, so one definition covers Live Dashboard and CloudWatch.

```elixir
summary("ingest.sheet.duration",
  event_name: [:meadow, :ingest, :sheet, :complete],
  measurement: :duration_ms,
  tags: [:status],
  unit: :millisecond
)
```

| You want | Use | Becomes |
| --- | --- | --- |
| How many times something happened | `counter/2` | `...count`, `Unit: "Count"` |
| How long something took, with percentiles | `summary/2` | `...summary`, every measurement sent |
| How many of something there are right now | `last_value/2` | `...last_value` |
| A running total | `sum/2` | `...sum` |

`summary` sends every raw measurement rather than a pre-computed statistic set, so
CloudWatch calculates exact percentiles. Only these four types are supported — a
`distribution` is silently warned about and ignored.

### 2. Name a measurement the event actually carries

**This is the trap.** The reporter drops any event whose measurement comes back `nil`:

```elixir
is_nil(measurement) -> cache   # from TelemetryMetricsCloudwatch.Cache
```

A metric's measurement defaults to the last segment of its *name*. So
`counter("pipeline.action.count", event_name: [..., :action, :stop])` would look for
`measurements[:count]`, which the stop event does not have — and the counter would
silently never fire. Always pass `measurement:` explicitly, naming a key the event really
carries. For a counter the value is ignored; only its presence matters.

There is a test (`every metric extracts a number from the event it listens to`) that runs
each metric's measurement against its event's real measurement map. Add your event there.

### 3. Emit the event

For something with a start and an end, use a span. For a point-in-time fact, use
`execute`:

```elixir
:telemetry.execute(
  [:meadow, :ingest, :sheet, :complete],
  %{duration_ms: elapsed},
  %{status: "ok"}
)
```

Conventions:

- **Measurements are numbers; metadata is context.** Anything that becomes a dimension
  belongs in metadata.
- **Name the unit when it is not native.** `:telemetry.span/3` reports `:duration` in
  native units; a wall-clock difference you computed is not native, so call it
  `:duration_ms`.
- **Classify dimension values at emit time**, as `Handlers.file_set_dimensions/1` does,
  so metadata carries `"video"` rather than `"video/mp4"`.
- **Never let a dimension value be `nil` or `""`.** CloudWatch rejects empty dimensions,
  so coalesce with `|| "unknown"` at the point of emission.

### 4. Transform, only if you have to

A handler is needed when the measurement does not exist in the event that triggers it.
`Meadow.Telemetry.Handlers` has exactly one: a completed file set's end-to-end latency has
to be looked up, so the action stop event is re-emitted as
`[:meadow, :pipeline, :file_set, :complete]`.

If you add one, add the event to `@events` and wrap the clause in a rescue —
**`:telemetry` permanently detaches any handler that raises**, so one malformed event
would take the transform out until the next restart, with a single log line to show for
it.

### 5. Measuring an absence

Some things cannot be measured by an event, because what you care about is the event *not*
arriving. A MediaConvert job that fails without a state change produces no
`TranscodeComplete`, so it can never appear in the duration histogram. Those are sampled
by `:telemetry_poller` calling `Meadow.Metrics.Probes.run/0`:

```elixir
def run do
  report_while_nonzero([:meadow, :pipeline, :transcode, :stalled], stalled_transcodes())
  :ok
end
```

Use `report_while_nonzero/2` for a count that is usually zero. The reporter clears its
`last_value` cache on every push, so a value that stops being emitted stops being
published — which is what you want for something almost always nothing. But a probe that
simply goes quiet at zero never reports the *recovery*: the metric's last datapoint stays
non-zero and an alarm on it never clears. `report_while_nonzero/2` emits the drop exactly
once and then goes quiet.

### 6. Test it

```elixir
# The event fires with the metadata the dimensions come from.
:telemetry.execute([:meadow, :ingest, :sheet, :complete], %{duration_ms: 500}, %{status: "ok"})
assert_received {:telemetry, _event, %{duration_ms: 500}, %{status: "ok"}}

# It survives the definitions, the keep predicate and the cache.
assert "ingest.sheet.duration.summary" in pending_names()
```

`Meadow.MetricsTest` starts a real reporter in dry-run mode and asserts on
`Meadow.Metrics.pending/0`, which is the only level that catches a metric silently
dropped for a missing measurement or a mistyped tag.

Assert dimension *values*, not just that a metric exists. A metric whose dimensions are
all `"unknown"` still has the right name — that exact gap once hid a bug where every
action was tagged `"unknown"`.

## Rules that matter

**Dimension values must be bounded.** A metric is billed per namespace + name +
dimension-value combination. An unbounded value — a file set id, a full mime type, an
error message — mints a metric per distinct value. `action` (~12) and `outcome` (~4) are
deliberately small. The reporter sends at most 10 dimensions per metric.

**Never add a node or host dimension.** CloudWatch merges datapoints sharing a name,
dimension set and period, so each node publishes its own aggregate and the totals come out
globally correct with no coordination. A node dimension multiplies the billed metric count
by the task count and gives up that free merge.

**`:telemetry.span/3` hands the stop event only what the span function returns.** The
start metadata is *not* merged in — though it is for the `exception` event, which makes
the asymmetry easy to miss. Name everything the metric needs in the stop metadata:

```elixir
metadata = span_metadata(action, data)

:telemetry.span([:meadow, :pipeline, :action], metadata, fn ->
  {action.process(data, attrs), Map.put(metadata, :outcome, outcome(result))}
end)
```

Getting this wrong does not fail loudly: the metric still publishes, tagged `"unknown"`.

**CloudWatch does not aggregate across dimension values.** Querying
`pipeline.action.duration.summary` without an `action` returns nothing at all — dimensions
are part of a metric's identity, not a filter. Use a `SEARCH()` expression for
cross-action totals rather than publishing a roll-up metric.

**Metrics cannot be deleted.** One stops being billed as soon as it stops receiving data,
but stays visible in `ListMetrics` for 15 months. A one-off error outcome leaves a
permanent ghost series in dashboards.

## Cost

$0.30 per custom metric per month for the first 10,000, prorated hourly and metered only
in the hours a metric actually receives data.

| | |
| --- | --- |
| One write, never again | ~$0.0004, once |
| An 8-hour dev session, ~80 metrics | ~$0.26 |
| Left publishing continuously, ~80 metrics | ~$24/month |

`PutMetricData` calls fall under CloudWatch's always-free 1M API requests; the reporter
chunks at 20 metrics per request and pushes once a minute.
