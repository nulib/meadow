defmodule MeadowWeb.MCP.UpdatePlanChange do
  @moduledoc """
  MCP tool for updating a PlanChange entry with proposed modifications.

  This tool is used by the AI agent to populate pending plan changes with actual
  proposed modifications (add/delete/replace operations) and transition them to
  the 'proposed' status.

  Controlled term fields (subject, contributor, creator, genre, language, location,
  style_period, technique) are automatically enriched with labels from authority sources.

  Coded term fields (rights_statement, license) are automatically enriched with labels
  from the code list.

  ## Example Usage

      # Update a pending change with proposed modifications
      %{
        id: "change-uuid",
        add: %{
          descriptive_metadata: %{
            date_created: ["1896-11-10"]
          }
        },
        status: "proposed"
      }

      # Update with controlled terms (labels will be auto-fetched if not provided)
      %{
        id: "change-uuid",
        add: %{
          descriptive_metadata: %{
            subject: [
              %{
                term: %{id: "http://id.loc.gov/authorities/subjects/sh85080672"},
                role: %{id: "TOPICAL", scheme: "subject_role"}
              }
            ]
          }
        },
        status: "proposed"
      }

      # Update with multiple operations
      %{
        id: "change-uuid",
        add: %{
          descriptive_metadata: %{
            contributor: [
              %{
                term: %{id: "http://id.loc.gov/authorities/names/n79129109"},
                role: %{id: "pht", scheme: "marc_relator"}
              }
            ]
          }
        },
        delete: %{
          descriptive_metadata: %{
            subject: [
              %{
                term: %{id: "http://id.loc.gov/authorities/subjects/sh85101207"},
                role: %{id: "TOPICAL", scheme: "subject_role"}
              }
            ]
          }
        },
        status: "proposed"
      }
  """

  use Anubis.Server.Component,
    type: :tool,
    name: "update_plan_change",
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Data.{CodedTerms, ControlledTerms, Planner}
  alias Meadow.Repo
  require Logger

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)a
  @coded_fields ~w(license rights_statement)a

  schema do
    field(:id, :string,
      description: "The UUID of the PlanChange to update",
      required: true
    )

    field(:add, :map, description: "Map of values to append to existing work data")

    field(:delete, :map, description: "Map of values to remove from existing work data")

    field(:replace, :map, description: "Map of values to fully replace in work data")

    field(:status, :string,
      description: "Status: pending, proposed, approved, rejected, completed, error"
    )

    field(:notes, :string, description: "Optional notes about this change")
  end

  def name, do: "update_plan_change"

  @impl true
  def execute(%{id: id} = request, frame) do
    Logger.debug("MCP Server updating PlanChange: #{id}")

    case fetch_plan_change(id) do
      {:ok, change} ->
        attrs = build_attrs(request)

        case Planner.update_plan_change(change, attrs) do
          {:ok, updated_change} ->
            updated_change = Repo.preload(updated_change, :plan)
            {:reply, Response.tool() |> Response.json(serialize_change(updated_change)), frame}

          {:error, reason} ->
            {:error, MCPError.execution(reason), frame}
        end

      {:error, reason} ->
        {:error, MCPError.execution(reason), frame}
    end
  end

  defp fetch_plan_change(id) do
    case Planner.get_plan_change(id) do
      nil -> {:error, "PlanChange with id #{id} not found"}
      change -> {:ok, change}
    end
  end

  defp build_attrs(request) do
    request
    |> Map.take([:add, :delete, :replace, :status, :notes])
    |> enrich_controlled_terms()
  end

  defp serialize_change(change) do
    %{
      id: change.id,
      plan_id: change.plan_id,
      work_id: change.work_id,
      add: change.add,
      delete: change.delete,
      replace: change.replace,
      status: change.status,
      user: change.user,
      notes: change.notes,
      completed_at: change.completed_at,
      error: change.error,
      inserted_at: change.inserted_at,
      updated_at: change.updated_at,
      plan: serialize_plan(change.plan)
    }
  end

  defp serialize_plan(plan) do
    %{
      id: plan.id,
      prompt: plan.prompt,
      query: plan.query,
      status: plan.status,
      user: plan.user,
      notes: plan.notes,
      completed_at: plan.completed_at,
      error: plan.error,
      inserted_at: plan.inserted_at,
      updated_at: plan.updated_at
    }
  end

  # Enrichment functions for controlled terms

  defp enrich_controlled_terms(attrs) do
    attrs
    |> Map.update(:add, nil, &enrich_metadata_section/1)
    |> Map.update(:delete, nil, &enrich_metadata_section/1)
    |> Map.update(:replace, nil, &enrich_metadata_section/1)
  end

  defp enrich_metadata_section(nil), do: nil

  defp enrich_metadata_section(section) when is_map(section) do
    descriptive_metadata =
      section
      |> Map.get(:descriptive_metadata, Map.get(section, "descriptive_metadata"))
      |> enrich_descriptive_metadata()

    if descriptive_metadata do
      section
      |> Map.delete("descriptive_metadata")
      |> Map.put(:descriptive_metadata, descriptive_metadata)
    else
      section
    end
  end

  defp enrich_metadata_section(section), do: section

  defp enrich_descriptive_metadata(nil), do: nil

  defp enrich_descriptive_metadata(metadata) when is_map(metadata) do
    metadata
    |> enrich_controlled_fields()
    |> enrich_coded_fields()
  end

  defp enrich_descriptive_metadata(metadata), do: metadata

  defp enrich_controlled_fields(metadata) do
    Enum.reduce(@controlled_fields, metadata, fn field, acc ->
      field_string = Atom.to_string(field)

      case Map.get(acc, field, Map.get(acc, field_string)) do
        nil ->
          acc

        values when is_list(values) ->
          enriched_values = Enum.map(values, &enrich_controlled_term_entry/1)

          acc
          |> Map.delete(field_string)
          |> Map.put(field, enriched_values)

        value ->
          enriched_value = enrich_controlled_term_entry(value)

          acc
          |> Map.delete(field_string)
          |> Map.put(field, enriched_value)
      end
    end)
  end

  defp enrich_coded_fields(metadata) do
    Enum.reduce(@coded_fields, metadata, fn field, acc ->
      field_string = Atom.to_string(field)

      case Map.get(acc, field, Map.get(acc, field_string)) do
        nil ->
          acc

        value when is_map(value) ->
          enriched_value =
            value
            |> atomize_keys()
            |> enrich_coded_term()

          acc
          |> Map.delete(field_string)
          |> Map.put(field, enriched_value)

        _value ->
          acc
      end
    end)
  end

  defp enrich_controlled_term_entry(entry) when is_map(entry) do
    entry
    |> atomize_keys()
    |> enrich_term()
    |> enrich_role()
  end

  defp enrich_controlled_term_entry(entry), do: entry

  defp enrich_term(%{term: term} = entry) when is_map(term) do
    enriched_term =
      term
      |> atomize_keys()
      |> enrich_term_with_label()

    Map.put(entry, :term, enriched_term)
  end

  defp enrich_term(entry), do: entry

  defp enrich_term_with_label(%{id: _id, label: label} = term) when not is_nil(label) do
    # Label already exists, don't overwrite
    term
  end

  defp enrich_term_with_label(%{id: id} = term) when is_binary(id) do
    case ControlledTerms.fetch(id) do
      {{:ok, _}, %{label: label}} ->
        Map.put(term, :label, label)

      {:error, reason} ->
        Logger.warning("Failed to fetch label for controlled term #{id}: #{inspect(reason)}")
        term

      _ ->
        term
    end
  end

  defp enrich_term_with_label(term), do: term

  defp enrich_role(%{role: role} = entry) when is_map(role) do
    enriched_role =
      role
      |> atomize_keys()
      |> enrich_role_with_label()

    Map.put(entry, :role, enriched_role)
  end

  defp enrich_role(entry), do: entry

  defp enrich_role_with_label(%{id: _id, scheme: _scheme, label: label} = role)
       when not is_nil(label) do
    # Label already exists, don't overwrite
    role
  end

  defp enrich_role_with_label(%{id: id, scheme: scheme} = role)
       when is_binary(id) and is_binary(scheme) do
    case CodedTerms.get_coded_term(id, scheme) do
      {{:ok, _}, %{label: label}} ->
        Map.put(role, :label, label)

      nil ->
        Logger.warning("Failed to fetch label for coded term #{id} in scheme #{scheme}")
        role

      _ ->
        role
    end
  end

  defp enrich_role_with_label(role), do: role

  defp enrich_coded_term(%{id: _id, scheme: _scheme, label: label} = term)
       when not is_nil(label) do
    # Label already exists, don't overwrite
    term
  end

  defp enrich_coded_term(%{id: id, scheme: scheme} = term)
       when is_binary(id) and is_binary(scheme) do
    case CodedTerms.get_coded_term(id, scheme) do
      {{:ok, _}, %{label: label}} ->
        Map.put(term, :label, label)

      nil ->
        Logger.warning("Failed to fetch label for coded term #{id} in scheme #{scheme}")
        term

      _ ->
        term
    end
  end

  defp enrich_coded_term(term), do: term

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp atomize_keys(value), do: value
end
