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
  # Fields with arrays of objects containing coded terms
  @nested_coded_fields ~w(notes related_url)a

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

    with {:ok, change} <- fetch_plan_change(id),
         {:ok, attrs} <- build_attrs_result(request),
         {:ok, updated_change} <- Planner.update_plan_change(change, attrs) do
      updated_change = Repo.preload(updated_change, :plan)
      {:reply, Response.tool() |> Response.json(serialize_change(updated_change)), frame}
    else
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
    |> validate_coded_terms()
  end

  defp build_attrs_result(request) do
    case build_attrs(request) do
      {:error, _} = error -> error
      attrs -> {:ok, attrs}
    end
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
    |> enrich_nested_coded_fields()
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

  defp enrich_nested_coded_fields(metadata) do
    Enum.reduce(@nested_coded_fields, metadata, fn field, acc ->
      field_string = Atom.to_string(field)

      case Map.get(acc, field, Map.get(acc, field_string)) do
        nil ->
          acc

        values when is_list(values) ->
          enriched_values = Enum.map(values, &enrich_nested_coded_entry(field, &1))

          acc
          |> Map.delete(field_string)
          |> Map.put(field, enriched_values)

        _value ->
          acc
      end
    end)
  end

  # Enrich notes entries (have a 'type' coded term)
  defp enrich_nested_coded_entry(:notes, entry) when is_map(entry) do
    entry
    |> atomize_keys()
    |> enrich_note_type()
  end

  # Enrich related_url entries (have a 'label' coded term)
  defp enrich_nested_coded_entry(:related_url, entry) when is_map(entry) do
    entry
    |> atomize_keys()
    |> enrich_related_url_label()
  end

  defp enrich_nested_coded_entry(_field, entry), do: entry

  defp enrich_note_type(%{type: type} = entry) when is_map(type) do
    enriched_type =
      type
      |> atomize_keys()
      |> enrich_coded_term()

    Map.put(entry, :type, enriched_type)
  end

  defp enrich_note_type(entry), do: entry

  defp enrich_related_url_label(%{label: label} = entry) when is_map(label) do
    enriched_label =
      label
      |> atomize_keys()
      |> enrich_coded_term()

    Map.put(entry, :label, enriched_label)
  end

  defp enrich_related_url_label(entry), do: entry

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

  # Validation functions for coded terms

  defp validate_coded_terms({:error, _} = error), do: error

  defp validate_coded_terms(attrs) do
    with :ok <- validate_operation_coded_terms(attrs, :add),
         :ok <- validate_operation_coded_terms(attrs, :replace) do
      attrs
    else
      {:error, message} -> {:error, message}
    end
  end

  defp validate_operation_coded_terms(attrs, operation) do
    case Map.get(attrs, operation) do
      nil -> :ok
      operation_data -> validate_coded_terms_in_section(operation_data, Atom.to_string(operation))
    end
  end

  defp validate_coded_terms_in_section(section, path) when is_map(section) do
    case Map.get(section, :descriptive_metadata) do
      nil ->
        :ok

      metadata ->
        with :ok <- validate_direct_coded_fields(metadata, path),
             :ok <- validate_role_coded_terms(metadata, path) do
          validate_nested_coded_fields(metadata, path)
        end
    end
  end

  defp validate_coded_terms_in_section(_section, _path), do: :ok

  # Validate direct coded fields (license, rights_statement)
  defp validate_direct_coded_fields(metadata, path) do
    Enum.reduce_while(@coded_fields, :ok, fn field, :ok ->
      validate_single_coded_field(metadata, field, path)
    end)
  end

  defp validate_single_coded_field(metadata, field, path) do
    case Map.get(metadata, field) do
      nil ->
        {:cont, :ok}

      %{id: id, scheme: scheme} = term ->
        field_path = "#{path}.descriptive_metadata.#{field}"
        validate_and_wrap_result(validate_coded_term(id, scheme, term, field_path))

      _ ->
        {:cont, :ok}
    end
  end

  # Validate role coded terms in controlled fields
  defp validate_role_coded_terms(metadata, path) do
    Enum.reduce_while(@controlled_fields, :ok, fn field, :ok ->
      validate_controlled_field_roles(metadata, field, path)
    end)
  end

  defp validate_controlled_field_roles(metadata, field, path) do
    case Map.get(metadata, field) do
      nil ->
        {:cont, :ok}

      values when is_list(values) ->
        field_path = "#{path}.descriptive_metadata.#{field}"
        validate_and_wrap_result(validate_roles_in_list(values, field_path))

      _ ->
        {:cont, :ok}
    end
  end

  defp validate_roles_in_list(values, base_path) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, idx}, :ok ->
      validate_single_role(entry, idx, base_path)
    end)
  end

  defp validate_single_role(entry, idx, base_path) do
    case entry do
      %{role: %{id: id, scheme: scheme}} = role_map ->
        role_path = "#{base_path}[#{idx}].role"
        validate_and_wrap_result(validate_coded_term(id, scheme, role_map.role, role_path))

      _ ->
        {:cont, :ok}
    end
  end

  # Validate nested coded fields (notes, related_url)
  defp validate_nested_coded_fields(metadata, path) do
    Enum.reduce_while(@nested_coded_fields, :ok, fn field, :ok ->
      validate_nested_coded_field_values(metadata, field, path)
    end)
  end

  defp validate_nested_coded_field_values(metadata, field, path) do
    case Map.get(metadata, field) do
      nil ->
        {:cont, :ok}

      values when is_list(values) ->
        field_path = "#{path}.descriptive_metadata.#{field}"
        validate_and_wrap_result(validate_nested_coded_list(field, values, field_path))

      _ ->
        {:cont, :ok}
    end
  end

  defp validate_nested_coded_list(:notes, values, base_path) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, idx}, :ok ->
      validate_note_type(entry, idx, base_path)
    end)
  end

  defp validate_nested_coded_list(:related_url, values, base_path) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, idx}, :ok ->
      validate_related_url_label(entry, idx, base_path)
    end)
  end

  defp validate_nested_coded_list(_field, _values, _base_path), do: :ok

  defp validate_note_type(entry, idx, base_path) do
    case entry do
      %{type: %{id: id, scheme: scheme}} = type_map ->
        type_path = "#{base_path}[#{idx}].type"
        validate_and_wrap_result(validate_coded_term(id, scheme, type_map.type, type_path))

      _ ->
        {:cont, :ok}
    end
  end

  defp validate_related_url_label(entry, idx, base_path) do
    case entry do
      %{label: %{id: id, scheme: scheme}} = label_map ->
        label_path = "#{base_path}[#{idx}].label"
        validate_and_wrap_result(validate_coded_term(id, scheme, label_map.label, label_path))

      _ ->
        {:cont, :ok}
    end
  end

  # Helper to wrap validation results for reduce_while
  defp validate_and_wrap_result(:ok), do: {:cont, :ok}
  defp validate_and_wrap_result(error), do: {:halt, error}

  defp validate_coded_term(id, scheme, term, field_path)
       when is_binary(id) and is_binary(scheme) do
    case CodedTerms.get_coded_term(id, scheme) do
      nil ->
        valid_ids = list_valid_coded_term_ids(scheme)
        error_msg = build_validation_error(field_path, id, scheme, valid_ids, term)
        {:error, error_msg}

      {{:ok, _}, _term} ->
        :ok

      _other ->
        {:error, "Unexpected error validating coded term #{id} in scheme #{scheme}"}
    end
  rescue
    e ->
      Logger.error("Exception during coded term validation: #{inspect(e)}")
      {:error, "Error validating coded term #{id} in scheme #{scheme}"}
  end

  defp validate_coded_term(_id, _scheme, _term, _path), do: :ok

  defp list_valid_coded_term_ids(scheme) do
    try do
      scheme
      |> CodedTerms.list_coded_terms()
      |> Enum.map(& &1.id)
      |> Enum.take(10)
    rescue
      _ -> []
    end
  end

  defp build_validation_error(path, id, scheme, valid_ids, term) do
    base_msg =
      "Invalid coded term in '#{path}': '#{id}' is not a valid term for scheme #{String.upcase(scheme)}."

    suggestions =
      if Enum.empty?(valid_ids) do
        ""
      else
        id_list = Enum.join(valid_ids, ", ")
        " Valid options include: #{id_list}"
      end

    label_info =
      case Map.get(term, :label) do
        nil -> ""
        label -> " (attempted label: '#{label}')"
      end

    base_msg <> label_info <> suggestions
  end
end
