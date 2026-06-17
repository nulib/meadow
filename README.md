# Meadow

[![Build](https://github.com/nulib/meadow/actions/workflows/test.yml/badge.svg)](https://github.com/nulib/meadow/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/nulib/meadow/badge.svg)](https://coveralls.io/github/nulib/meadow)
<!-- [![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=nulib/meadow)](https://dependabot.com) -->

## Prerequisites

- [NUL's AWS Cloud Developer Environment](https://github.com/nulib/aws-developer-environment) setup

## Initial startup:

- From the `meadow` project root, `cd app`.
- Install Elixir dependencies with `mix deps.get`
- Run `mix meadow.setup`. This creates the Sequins pipeline, S3 buckets, and database.
- Install JavaScript dependencies with `mix assets.install`
  - `assets.install` looks for all `bun.lock` files project-wide and runs `bun install --frozen-lockfile` in each directory found, so you don't need to run `bun install` in individual directories.
- run `sgport open all 3001`
- Start the Phoenix server with `mix phx.server` (or `iex -S mix phx.server` if you want to an interactive shell).

Now you can visit [`https://[YOURENV].dev.rdc.library.northwestern.edu:3001/`](https://[YOURENV].dev.rdc.library.northwestern.edu:3001/) from your browser.

## Stopping the application

You can stop the Phoenix server with `Ctrl + C` twice

## Clearing and resetting data

If you need to clear your data and reset the entire development environment, from `meadow/app` run:

```bash
mix ecto.reset
mix meadow.search.clear
mix meadow.pipeline.purge
clean-s3 dev -y
```
...then
```bash
mix deps.get
mix meadow.setup
mix phx.server
```

### Dependencies

You may need to run `mix deps.get` again if new dependencies have been added

You may need to run `mix assets.install` if new `node` packages have been added

### Database

If you need to reset the database you can run `mix ecto.reset` which will drop + create + migrate the database

If you just want to run the migrations but leave the data intact, you can just do `mix ecto.migrate`

If you would like to interact directly with the database

### Run the Elixir test suite

#### Full Continuous Integration

From the Meadow root directory:

```bash
make ci
```

This runs JS tests, starts localstack + pipeline services, provisions test infrastructure, runs Elixir tests with the required environment (`AWS_LOCALSTACK=true`), and then tears down localstack automatically.

#### Run only Elixir tests with automatic setup

```bash
make app-test
```

#### Advanced/manual workflow

```bash
make localstack-provision
make app-test [test args...]
cd ..
make localstack-stop
```

**Note:** Do not run Meadow with `AWS_LOCALSTACK=true` set in your normal dev shell.

### GraphQL API

You can visit the GraphiQL interface at: [`https://[YOURENV].dev.rdc.library.northwestern.edu:3001/api/graphiql`](https:/[YOURENV].dev.rdc.library.northwestern.edu:3001/api/graphiql)

### Livebook Integration

To start meadow with superuser Livebook integration, run: `MEADOW_ROOT/bin/meadow-livebook [iex arguments]`

For example, from Meadow's root directory: `./bin/meadow-livebook phx.server`

### Opensearch Dashboard

- To start: `es-proxy start`
- To stop: `es-proxy stop`
- See the console output for the url to the dashboard

### Digital Collections API

In order to see data and thumbnails from your current environment, you'll need to run the DC API alongside Meadow. Follow the instructions for [Running the API locally](https://github.com/nulib/dc-api-v2#running-the-api-locally) and [Running the API locally via our AWS dev domain](Running the API locally via our AWS dev domain) to get it running.

### Reindexing data

To force an Elasticsearch re-index, and not wait for the 2-minute cycle to kick in when updating a Meadow item:

Run the interactive shell in a terminal tab

```bash
iex -S mix
```

And force a re-index:

```elixir
Meadow.Data.Indexer.reindex_all()
```

### Sample ingest mix task

`mix meadow.sample_ingest` creates a project (or reuses one), uploads sample
fixture media (`coffee.tif`, `small.m4v`, `details.json`,
`Donohue_002_01.vtt`) and a generated CSV to the current environment's S3
buckets, then runs an ingest end-to-end. Useful for populating an AWS dev
environment with realistic ingest sheet data without clicking through the UI.

Work and file set accession numbers in the generated CSV are fresh UUIDs per
run, so the task can be re-run without uniqueness collisions.

#### Options

| Option                 | Description                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `--title <prefix>`     | Sheet title prefix (default: `Sample Ingest <unix-ts>`).                                                                                                                 |
| `--project <title>`    | Existing project title to ingest into. Reused if it exists; otherwise created. If omitted, a new project is created using `--title`.                                     |
| `--fixture-dir <path>` | Directory to read source media from (default: `test/fixtures`).                                                                                                          |
| `--ai`                 | Create the sheet as an AI ingest (`ai_ingest: true`).                                                                                                                    |
| `--mode <mode>`        | One of: `validate` (stop after validation), `preview` (AI only — runs `AIPreview` and stops at `awaiting_approval`), `ingest` (default — auto-approve and create works). |
| `--keep-pending`       | Alias for `--mode validate`.                                                                                                                                             |

`--mode preview` requires `--ai`. With `--ai --mode ingest`, the AI preview is
generated synchronously and the sheet is then approved and ingested into
works.

#### Examples

```bash
cd app

# Default: new project, full ingest, no AI
mix meadow.sample_ingest

# Custom title
mix meadow.sample_ingest --title "Smoke Test"

# Reuse (or create) an existing project
mix meadow.sample_ingest --project "QA Sandbox"

# Stop after validation, leave sheet for manual UI approval
mix meadow.sample_ingest --mode validate

# AI ingest, stop at awaiting_approval (test the approval UI)
mix meadow.sample_ingest --ai --mode preview

# AI ingest, run all the way through to approved + works
mix meadow.sample_ingest --ai --mode ingest
```

On validation failure, the task logs `Sheets.ingest_errors/1` and exits
non-zero.

### AI Agent Plans

Meadow supports AI agent-generated plans for batch modifications to works. The system uses a two-table structure that allows agents to propose work-specific changes based on high-level prompts.

#### Data Model

**Plans** - High-level task definitions
- `prompt`: Natural language instruction (e.g., "Add a date_created EDTF string for the work based on the work's existing description, creator, and temporal subjects")
- `query`: OpenSearch query string identifying target works
  - Collection query: `"collection.id:abc-123"`
  - Specific works: `"id:(work-id-1 OR work-id-2 OR work-id-3)"`
- `status`: `:pending, `:proposed`, `:approved`, `:rejected`, `:completed`, or `:error`

**PlanChanges** - Work-specific modifications
- `plan_id`: Foreign key to parent plan
- `work_id`: Specific work being modified
- `add`: Map of values to append to existing work data
- `delete`: Map of values to remove from existing work data
- `replace`: Map of values to fully replace in work data
- `status`: Individual approval/rejection tracking

Each PlanChange must specify at least one operation (`add`, `delete`, or `replace`).

#### PlanChange payloads

- `add` merges values into existing metadata. For lists (like subjects or notes) the values are appended when they are not already present. Scalar fields (e.g., `title`) are merged according to the context (`:append` for `add`, `:replace` for `replace`).
- `delete` removes the provided values verbatim. For controlled vocabularies this means the JSON structure must match what is stored in the database (role/term maps). The planner normalizes structs and string-keyed maps automatically when applying changes.
- `replace` overwrites existing values for the provided keys. Use this when the existing content should be replaced entirely instead of appended or removed.

Controlled metadata entries (subjects, creators, contributors, etc.) follow the shape below. For subjects you must supply both the `role` (with at least `id`/`scheme`) and the `term.id`; extra fields such as `label` or `variants` are ignored when applying but can be included when working with structs in IEx:

```elixir
%{
  descriptive_metadata: %{
    subject: [
      %{
        role: %{id: "TOPICAL", scheme: "subject_role"},
        term: %{
          id: "http://id.loc.gov/authorities/subjects/sh85141086",
          label: "Universities and colleges",
          variants: ["Colleges", "Higher education institutions"]
        }
      }
    ]
  }
}
```

When constructing PlanChanges you can mix-and-match operations as needed. For example, to remove an outdated subject and add a new one in a single change:

```elixir
delete: %{
  descriptive_metadata: %{
    subject: [
      %{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: "mock1:result2"}}
    ]
  }
},
add: %{
  descriptive_metadata: %{
    subject: [
      %{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: "mock1:result5"}}
    ]
  }
}
```

#### Example Workflows

**Adding new metadata:**
```elixir
# 1. Create a plan with a query - PlanChanges are auto-generated for matching works
{:ok, plan} = Meadow.Data.Planner.create_plan(%{
  prompt: "Add a date_created EDTF string for the work based on the work's existing description, creator, and temporal subjects",
  query: "collection.id:abc-123"
})

# 2. Agent updates each auto-generated PlanChange with work-specific values
changes = Meadow.Data.Planner.list_plan_changes(plan.id)

change_a = Enum.at(changes, 0)
{:ok, updated_change_a} = Meadow.Data.Planner.update_plan_change(change_a, %{
  add: %{descriptive_metadata: %{date_created: ["1896-11-10"]}}
})

change_b = Enum.at(changes, 1)
{:ok, updated_change_b} = Meadow.Data.Planner.update_plan_change(change_b, %{
  add: %{descriptive_metadata: %{date_created: ["1923-05"]}}
})
```

**Removing unwanted values:**
```elixir
# Remove extraneous subject headings
{:ok, change} = Meadow.Data.Planner.create_plan_change(%{
  plan_id: plan.id,
  work_id: "work-id",
  delete: %{
    descriptive_metadata: %{
      subject: [
        %{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: "http://example.org/photograph"}},
        %{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: "http://example.org/image"}}
      ]
    }
  }
})
```

**Replacing existing values:**
```elixir
# Replace the title
{:ok, change} = Meadow.Data.Planner.create_plan_change(%{
  plan_id: plan.id,
  work_id: "work-id",
  replace: %{descriptive_metadata: %{title: "New Title"}}
})
```

**Reviewing and applying:**
```elixir
# 3. User reviews and approves
{:ok, _} = Meadow.Data.Planner.approve_plan(plan, "user@example.com")
{:ok, _} = Meadow.Data.Planner.approve_plan_change(change_a, "user@example.com")
{:ok, _} = Meadow.Data.Planner.approve_plan_change(change_b, "user@example.com")

# 4. Apply approved changes
{:ok, completed_plan} = Meadow.Data.Planner.apply_plan(plan)
```

### ArchivesSpace Integration

Meadow works and collections can be linked to ArchivesSpace records so that metadata work done in Meadow (batch AI agent plans, transcription, manual edits) is pushed back to the finding aid automatically.

- A **work** links to an ArchivesSpace **archival object** (e.g. `/repositories/2/archival_objects/1234`)
- A **collection** links to an ArchivesSpace **resource**
- Links live in the `archives_space_links` table along with their sync state (`linked`, `pending`, `synced`, or `error`), the last error message, and the last successful sync time

#### What gets synced

Syncing is **one-way (Meadow → ArchivesSpace)** and touches only the slice of the archival object Meadow owns:

| Meadow field | ArchivesSpace target |
| --- | --- |
| `title` | archival object title |
| `description` | `scopecontent` note labeled "Synced from Meadow" |
| `abstract` | `abstract` note labeled "Synced from Meadow" |
| `subject` (terms with authority URIs) | subject records, found-or-created by `authority_id`, linked to the archival object |
| `published` + `visibility` | a Meadow-managed **digital object** pointing at the work's Digital Collections URL, attached to the archival object as an instance |

Everything else on the archival object — archivist-authored notes, dates, extents, containers — is preserved: every sync GETs the record fresh, merges Meadow's fields into it, and POSTs it back (retrying on `lock_version` conflicts). Subjects are only ever added, never removed. Deleting a linked work deletes the Meadow-managed digital object but **never** touches the archival description; if the remote cleanup fails, the link is kept in an `error` state so it stays visible.

Syncing is event-driven: a WalEx listener on the `works` table (`Meadow.Events.Works.ArchivesSpace`) detects changes to synced fields on linked works and feeds a rate-limited processor, so no user action is required after a work is linked.

#### Configuration

The integration is enabled whenever an ArchivesSpace URL is configured (`Meadow.Config.archives_space_enabled?/0`). In deployed environments the URL, user, and password come from the `archives_space` secret. The API user needs permission to update archival objects and create digital objects and subjects in the linked repository — use a dedicated `meadow` user, not `admin`.

In **dev** and **test**, Meadow runs a built-in mock ArchivesSpace API (`Meadow.ArchivesSpace.MockServer`, ports 3947/3948 — same pattern as the EZID mock), so no real ArchivesSpace is needed.

#### Linking and syncing

Via GraphQL (all Editor-gated except the query):

```graphql
mutation {
  linkWorkToArchivesSpace(
    workId: "work-uuid"
    archivesSpaceUri: "/repositories/2/archival_objects/1234"
    refId: "ref48_optional"
  ) { id syncStatus }
}

mutation { syncWorkToArchivesSpace(workId: "work-uuid") { syncStatus syncError } }
mutation { unlinkWorkFromArchivesSpace(workId: "work-uuid") { id } }

query { archivesSpaceLink(workId: "work-uuid") { syncStatus syncError lastSyncedAt } }
query { archivesSpaceErrorLinks { workId archivesSpaceUri syncError } }
```

Or from IEx:

```elixir
work = Meadow.Data.Works.get_work!("work-uuid")
{:ok, link} = Meadow.ArchivesSpace.link_work(work, "/repositories/2/archival_objects/1234")

# Push immediately instead of waiting for the next change event:
Meadow.ArchivesSpace.Sync.sync_work(work.id)

# Review failures:
Meadow.ArchivesSpace.list_error_links()
```

#### Importing a resource from ArchivesSpace

`Meadow.ArchivesSpace.Importer` walks an ArchivesSpace resource (finding aid) and creates:

- One linked Meadow **collection** from the resource (title, scope note, EAD location as the finding aid URL)
- One linked, unpublished Meadow **work** per archival object at the requested levels of description (`file` and `item` by default), with title, scope/contents, abstract, and any subjects carrying resolvable authority URIs

The importer reads the tree via the `tree/root`/`tree/waypoint` endpoints rather than `ordered_records`, because the latter excludes unpublished and suppressed records — usually exactly the material that still needs metadata work. Archival objects that already have a linked work are skipped, so re-importing a resource only picks up newly added records. After import, the works are ready for batch agent plans or manual editing, and changes flow back to ArchivesSpace through the regular sync.

In the UI, ArchivesSpace ingest has its own **Dashboards → ArchivesSpace Imports** page (`/dashboards/archivesspace`). It lists previously imported finding aids — each linking to its Meadow collection (where staff revisit the works and run faceted batch edits) — and its **Ingest from ArchivesSpace** button (Manager-gated) searches ArchivesSpace resources by keyword (`archivesSpaceResourceSearch` query) and imports the chosen one (`importArchivesSpaceResource` mutation). The mutation creates and returns the linked collection immediately and imports the works in a supervised background task, so large finding aids don't tie up the request. Checking **Enable AI-generated metadata** (supermanager-gated) flags the imported works so their ingested images run through the AI metadata pipeline.

```bash
cd app
mix meadow.archives_space.import /repositories/2/resources/123
mix meadow.archives_space.import /repositories/2/resources/123 --levels file,item --accession-prefix "aspace:"
```

Or from IEx:

```elixir
{:ok, summary} = Meadow.ArchivesSpace.Importer.import_resource("/repositories/2/resources/123")
# summary => %{collection: %Collection{}, created: [works], skipped: [uris], errors: [{uri, reason}]}
```

Generated accession numbers are `aspace:<ref_id>`. Digitized file sets still arrive through the normal ingest pipeline; transcription requires media, so it applies only after file sets are attached to the imported works.

#### Running ArchivesSpace locally (Docker)

Dev defaults to a local ArchivesSpace, the same way it defaults to localstack. The repo includes a compose stack in `infrastructure/archivesspace/` ([ArchivesSpace's Docker distribution](https://docs.archivesspace.org/administration/docker/), trimmed to the app, MySQL, and Solr), wired into the root Makefile like localstack:

```bash
make archivesspace-wait   # start and block until the API responds (first boot takes 10+ minutes)
make archivesspace-stop   # stop; MySQL/Solr data persists in named volumes
make archivesspace-clean  # stop and delete all data volumes
```

The staff UI is at `http://localhost:8080` and the backend API at `http://localhost:8089` (credentials `admin`/`admin`). The dev config points Meadow at `http://localhost:8089` by default with `admin`/`admin`, so once the stack is up, `mix phx.server` just works — no extra configuration.

To use the lightweight in-process mock instead (no Docker, but empty and can't serve images), set `ARCHIVESSPACE_URL` to the mock server's port:

```bash
cd app
ARCHIVESSPACE_URL=http://localhost:3947 mix phx.server
```

For a non-default user or a remote instance, set the `archives_space` secret or override the whole map in `app/config/dev.local.exs`:

```elixir
config :meadow,
  archives_space: %{
    url: "http://localhost:8089",
    user: "admin",
    password: "admin"
  }
```

Populate the running instance with fixture data — a finding aid whose archival objects carry image digital objects, ready to exercise the ingest workflow — with:

```bash
cd app
mix meadow.archives_space.seed            # 5 image items into the configured (default :8089) instance
mix meadow.archives_space.seed --items 10
```

Note that the ArchivesSpace stack is **not** part of `make ci` or the localstack compose stack and never needs to be running for the test suite.

#### Tests

ArchivesSpace tests run against the in-process mock and need only the standard test environment (localstack + postgres + opensearch, provisioned automatically by the Make targets):

```bash
make app-test ARGS="test/meadow/archives_space test/meadow/archives_space_test.exs test/meadow/events/works/archives_space_test.exs test/meadow_web/schema/mutation/link_work_to_archives_space_test.exs test/meadow_web/schema/mutation/unlink_work_from_archives_space_test.exs test/meadow_web/schema/mutation/sync_work_to_archives_space_test.exs test/meadow_web/schema/query/archives_space_link_test.exs"
```

The WalEx event tests (`test/meadow/events/works/archives_space_test.exs`) run unsandboxed against the real database replication slot, like the ARK event tests.

A small number of tests are tagged `:archivesspace_integration` and run against a **real** ArchivesSpace (the Docker stack above) instead of the mock, to verify the app actually behaves the way the mock assumes — JSONModel validation, digital-object-component creation, and the `tree/root`/`tree/waypoint` walk the sync relies on. They cover both directions: importing a resource (`importer_integration_test.exs`) and pushing a transcription back out to a digital object component (`transcription_sync_integration_test.exs`, which exercises the full save-transcription → WalEx → sync path end to end).

They are excluded from the default suite, so start the stack first and opt in with the tag:

```bash
make archivesspace-wait   # first boot takes 10+ minutes
make app-test ARGS="test/meadow/archives_space --only archivesspace_integration"
```

Each test seeds its own ArchivesSpace records, so no manual data setup is needed.

### Doing development on the Meadow Pipeline lambdas

In the AWS developer environment, the lambdas associated with the pipeline are shared amongst developers. In order to do development and see whether it's working you can override the configuration to use the SAM pipeline the deployed lambdas.

In one terminal:
```bash
make pipeline-start
```

In another terminal:
```bash
cd app
USE_SAM_LAMBDAS=true iex -S mix phx.server
```


#### Deploying lambdas with SAM

The pipeline infrastructure is defined in `infrastructure/pipeline/template.yaml` and can be deployed with 
the AWS SAM CLI. There are `make` tasks to assist. Make sure `AWS_PROFILE` is set to the correct admin 
profile and logged in, and then:

```bash
make pipeline-deploy ENV=staging
```

### TypeScript/GraphQL Types

Meadow now supports TypeScript and GraphQL types in the React app. To generate types, run the following commands:

```bash
# Generate a local JSON version of GraphQL schema
mix graphql.schema.export -o priv/graphql/schema.json

# Generate TypeScript types for the UI
cd assets
bun run generate-types
```

Types will be generated in `meadow/app/assets/js/__generated__`. You can import them into React components like so:

```tsx
import type { FileSet, Work as WorkType } from "@js/__generated__/graphql";

const SomeComponent = ({ work }: { work: WorkType }) => {
  // ...
};
```

### Terraform

Meadow's Terraform code is stored in this repo. To run Terraform commands, you'll need to do the [configuration setup](https://github.com/nulib/repodev_planning_and_docs/blob/a36472895ae5c851f4f36b6f598dc5f666cea672/docs/2._Developer_Guides/Meadow/Terraform-Setup-on-Meadow.md)

### UI Customization

Meadow runs in Development, Staging and Production environments. To help distinguish environments (and avoid potential errors), Staging and Development environments support alternate, background colors.

#### Production

- A wrapper CSS class of `is-production-environment` wraps the `main` HTML element (in case anyone wants to target a selector for any reason).

#### Staging

- Supports a toggle background color switch in the site header
- Customize your own dev background color by updating the hex value for `localStorage` property `devBg`
- A wrapper CSS class of `is-staging-environment` wraps the `main` HTML element.

#### Development

- Supports a toggle background color switch in the site header
- Customize your own dev background color by updating the hex value for `localStorage` property `devBg`
- A wrapper CSS class of `is-development-environment` wraps the `main` HTML element.
