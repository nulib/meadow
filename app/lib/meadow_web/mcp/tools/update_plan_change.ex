defmodule MeadowWeb.MCP.Tools.UpdatePlanChange do
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
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Config
  alias Meadow.Data.{CodedTerms, Enrichment, Planner}
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
  alias Meadow.Data.Types
  alias Meadow.Repo
  require Logger

  @ai_note_prefix "Some metadata created with the assistance of AI"

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

  @impl true
  def execute(%{id: id} = request, frame) do
    Logger.debug("MCP Server updating PlanChange: #{id}")

    with {:ok, change} <- fetch_plan_change(id),
         {:ok, attrs} <- build_attrs_result(request, change),
         {:ok, updated_change} <- Planner.update_plan_change(change, attrs) do
      updated_change = Repo.preload(updated_change, :plan)
      maybe_auto_propose_plan(updated_change)
      {:reply, Response.tool() |> Response.structured(serialize_change(updated_change)), frame}
    else
      {:error, reason} ->
        {:error, MCPError.execution(error_message(reason)), frame}
    end
  rescue
    error ->
      {:error, MCPError.execution(error_message(error)), frame}
  end

  defp maybe_auto_propose_plan(%{status: :proposed, plan_id: plan_id, plan: %{status: :pending}}) do
    if Planner.count_pending_plan_changes(plan_id) == 0 do
      plan = Planner.get_plan(plan_id)

      case Planner.propose_plan(plan) do
        {:ok, _} ->
          Logger.debug("Auto-proposed plan #{plan_id} after last pending change was proposed")

        {:error, reason} ->
          Logger.warning("Failed to auto-propose plan #{plan_id}: #{inspect(reason)}")
      end
    end
  end

  defp maybe_auto_propose_plan(_), do: :ok

  defp fetch_plan_change(id) do
    case Planner.get_plan_change(id) do
      nil -> {:error, "PlanChange with id #{id} not found"}
      change -> {:ok, change}
    end
  end

  defp build_attrs(request, change) do
    model = Config.ai(:model)

    request
    |> Map.take([:add, :delete, :replace, :status, :notes])
    |> Enrichment.enrich_controlled_terms()
    |> validate_schema_conformance()
    |> inject_ai_note(model, change)
    |> validate_coded_terms()
  end

  defp build_attrs_result(request, change) do
    case build_attrs(request, change) do
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

  defp has_metadata_changes?(attrs) do
    Enum.any?([:add, :delete, :replace], fn key ->
      val = Map.get(attrs, key)
      not is_nil(val) and val != %{}
    end)
  end

  defp build_ai_note(model) do
    current_date = Date.utc_today() |> Date.to_iso8601()

    note_text =
      case model do
        nil ->
          "#{@ai_note_prefix} on #{current_date}"

        model_id ->
          "#{@ai_note_prefix} (#{model_id}) on #{current_date}"
      end

    %{note: note_text, type: %{id: "LOCAL_NOTE", scheme: "note_type", label: "Local Note"}}
  end

  defp inject_ai_note(attrs, _model, _change) when not is_map(attrs), do: attrs

  defp inject_ai_note(attrs, model, change) do
    if has_metadata_changes?(attrs) do
      ai_note = build_ai_note(model)

      updated_attrs =
        if ai_note_already_present?(attrs, change, ai_note),
          do: attrs,
          else: do_inject_ai_note(attrs, ai_note)

      normalize_ai_notes(updated_attrs)
    else
      attrs
    end
  end

  defp ai_note_already_present?(attrs, change, ai_note) do
    [
      Map.get(attrs, :add),
      Map.get(attrs, :replace),
      Map.get(change || %{}, :add),
      Map.get(change || %{}, :replace)
    ]
    |> Enum.flat_map(&section_notes/1)
    |> Enum.any?(&same_ai_note?(&1, ai_note))
  end

  defp section_notes(section) when is_map(section) do
    case metadata_section(section) do
      metadata when is_map(metadata) ->
        case map_value(metadata, :notes) do
          notes when is_list(notes) -> notes
          _ -> []
        end

      _ ->
        []
    end
  end

  defp section_notes(_section), do: []

  defp same_ai_note?(entry, _ai_note) when is_map(entry) do
    entry_note = map_value(entry, :note)
    entry_type = map_value(entry, :type)

    is_binary(entry_note) and
      String.starts_with?(entry_note, @ai_note_prefix) and
      is_map(entry_type) and
      map_value(entry_type, :id) == "LOCAL_NOTE" and
      map_value(entry_type, :scheme) == "note_type"
  end

  defp same_ai_note?(_entry, _ai_note), do: false

  defp do_inject_ai_note(attrs, ai_note) do
    replace_section = Map.get(attrs, :replace) || %{}
    replace_metadata = Map.get(replace_section, :descriptive_metadata) || %{}

    case map_value(replace_metadata, :notes) do
      replace_notes when is_list(replace_notes) ->
        updated_replace_metadata =
          Map.put(replace_metadata, :notes, append_unique_ai_note(replace_notes, ai_note))

        updated_replace_section =
          Map.put(replace_section, :descriptive_metadata, updated_replace_metadata)

        Map.put(attrs, :replace, updated_replace_section)

      _ ->
        add_section = Map.get(attrs, :add) || %{}
        descriptive_metadata = Map.get(add_section, :descriptive_metadata) || %{}
        existing_notes = map_value(descriptive_metadata, :notes) || []

        updated_descriptive_metadata =
          Map.put(descriptive_metadata, :notes, append_unique_ai_note(existing_notes, ai_note))

        updated_add_section =
          Map.put(add_section, :descriptive_metadata, updated_descriptive_metadata)

        Map.put(attrs, :add, updated_add_section)
    end
  end

  defp append_unique_ai_note(notes, ai_note) when is_list(notes) do
    if Enum.any?(notes, &same_ai_note?(&1, ai_note)) do
      notes
    else
      notes ++ [ai_note]
    end
  end

  defp normalize_ai_notes(attrs) when is_map(attrs) do
    attrs
    |> normalize_ai_notes_for_operation(:replace)
    |> normalize_ai_notes_for_operation(:add)
  end

  defp normalize_ai_notes(attrs), do: attrs

  defp normalize_ai_notes_for_operation(attrs, operation) do
    case Map.get(attrs, operation) do
      section when is_map(section) ->
        metadata = Map.get(section, :descriptive_metadata) || %{}
        notes = map_value(metadata, :notes)

        if is_list(notes) do
          normalized_notes = dedupe_ai_notes(notes)
          updated_metadata = Map.put(metadata, :notes, normalized_notes)
          updated_section = Map.put(section, :descriptive_metadata, updated_metadata)
          Map.put(attrs, operation, updated_section)
        else
          attrs
        end

      _ ->
        attrs
    end
  end

  defp dedupe_ai_notes(notes) do
    notes
    |> Enum.reduce({[], false}, fn note, {acc, seen_ai_note?} ->
      if same_ai_note?(note, nil) do
        if seen_ai_note? do
          {acc, true}
        else
          {[note | acc], true}
        end
      else
        {[note | acc], seen_ai_note?}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  # Validation functions for coded terms

  defp validate_schema_conformance({:error, _} = error), do: error

  defp validate_schema_conformance(attrs) when is_map(attrs) do
    with :ok <- validate_operation_schema(attrs, :add),
         :ok <- validate_operation_schema(attrs, :delete),
         :ok <- validate_operation_schema(attrs, :replace) do
      attrs
    else
      {:error, message} -> {:error, message}
    end
  end

  defp validate_operation_schema(attrs, operation) do
    case Map.get(attrs, operation) do
      nil ->
        :ok

      operation_section when is_map(operation_section) ->
        validate_descriptive_metadata_schema(operation_section, operation)

      _ ->
        {:error, "Operation '#{operation}' must be an object/map"}
    end
  end

  defp validate_descriptive_metadata_schema(section, operation) do
    case metadata_section(section) do
      nil ->
        :ok

      metadata when is_map(metadata) ->
        with :ok <- validate_metadata_changeset(metadata, operation) do
          validate_metadata_fields(metadata, operation)
        end

      _ ->
        {:error, "'#{operation}.descriptive_metadata' must be an object/map"}
    end
  end

  defp validate_metadata_changeset(metadata, operation) do
    normalized_metadata =
      metadata
      |> metadata_for_changeset_validation()
      |> stringify_map_keys()

    changeset = WorkDescriptiveMetadata.changeset(%WorkDescriptiveMetadata{}, normalized_metadata)

    if changeset.valid? do
      :ok
    else
      {:error,
       "Invalid '#{operation}.descriptive_metadata': #{format_changeset_errors(changeset)}"}
    end
  end

  # Controlled-term type casting performs authority resolution. We validate
  # controlled metadata entries separately (shape/role) and allow lookup failures
  # to pass through without rejecting the entire tool call.
  defp metadata_for_changeset_validation(metadata) when is_map(metadata) do
    Enum.reduce(controlled_fields(), metadata, fn field, acc ->
      acc
      |> Map.delete(field)
      |> Map.delete(Atom.to_string(field))
    end)
  end

  defp metadata_for_changeset_validation(metadata), do: metadata

  defp format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      msg
      |> format_changeset_error_message()
      |> interpolate_changeset_error_opts(opts)
    end)
    |> inspect()
  end

  defp format_changeset_error_message(message) when is_binary(message), do: message
  defp format_changeset_error_message(message), do: format_changeset_error_value(message)

  defp interpolate_changeset_error_opts(message, opts)
       when is_binary(message) and is_list(opts) do
    Enum.reduce(opts, message, fn {key, value}, acc ->
      String.replace(
        acc,
        "%{#{format_changeset_error_key(key)}}",
        format_changeset_error_value(value)
      )
    end)
  end

  defp interpolate_changeset_error_opts(message, _opts), do: message

  defp format_changeset_error_key(key) when is_atom(key), do: Atom.to_string(key)
  defp format_changeset_error_key(key) when is_binary(key), do: key
  defp format_changeset_error_key(key), do: inspect(key)

  defp format_changeset_error_value(value) when is_binary(value), do: value

  defp format_changeset_error_value(value) when is_atom(value) or is_number(value),
    do: to_string(value)

  defp format_changeset_error_value(value), do: inspect(value)

  # Ecto.Changeset.cast/4 rejects mixed atom/string keys in one params map.
  # Enrichment may atomize some controlled fields while others remain strings.
  # Normalize to string keys before schema validation.
  defp stringify_map_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      normalized_key =
        case key do
          atom when is_atom(atom) -> Atom.to_string(atom)
          other -> other
        end

      Map.put(acc, normalized_key, stringify_map_keys(value))
    end)
  end

  defp stringify_map_keys(list) when is_list(list), do: Enum.map(list, &stringify_map_keys/1)
  defp stringify_map_keys(value), do: value

  defp validate_metadata_fields(metadata, operation) do
    metadata
    |> Enum.reduce_while(:ok, fn {raw_field, value}, :ok ->
      field_path = "#{operation}.descriptive_metadata.#{field_name(raw_field)}"

      with {:ok, field} <- normalize_field(raw_field, field_path),
           :ok <- validate_allowed_field(field, field_path),
           :ok <- validate_field_operation(field, operation, field_path),
           :ok <- validate_field_value(field, value, field_path) do
        {:cont, :ok}
      else
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp normalize_field(field, _path) when is_atom(field), do: {:ok, field}

  defp normalize_field(field, path) when is_binary(field) do
    try do
      {:ok, String.to_existing_atom(field)}
    rescue
      ArgumentError ->
        {:error, "Unknown field '#{field}' in '#{path}'"}
    end
  end

  defp normalize_field(field, path),
    do: {:error, "Invalid field key '#{inspect(field)}' in '#{path}'"}

  defp validate_allowed_field(field, path) do
    if allowed_descriptive_field?(field) do
      :ok
    else
      {:error, "Field '#{field}' is not allowed in '#{path}'"}
    end
  end

  defp validate_field_operation(field, operation, path) do
    cond do
      operation == :delete and not controlled_field?(field) ->
        {:error, "'#{path}' cannot use delete. Only controlled fields support delete operations."}

      operation == :replace and controlled_field?(field) ->
        {:error, "'#{path}' cannot use replace. Controlled fields must use add/delete."}

      operation in [:add, :delete] and replace_only_field?(field) ->
        {:error, "'#{path}' must use replace and cannot use #{operation}."}

      true ->
        :ok
    end
  end

  defp validate_field_value(field, value, path) do
    cond do
      single_value_string_field?(field) ->
        validate_plain_string_field(value, path)

      controlled_field?(field) ->
        validate_controlled_field_entries(field, value, path)

      coded_field?(field) ->
        validate_coded_object(value, path)

      nested_coded_field?(field) ->
        validate_nested_coded_entries(field, value, path)

      date_field?(field) ->
        validate_date_field_values(value, path)

      true ->
        :ok
    end
  end

  defp validate_plain_string_field(value, path) when is_binary(value) do
    if json_blob_string?(value) do
      {:error, "'#{path}' must be plain text, not a JSON-serialized object/array string"}
    else
      :ok
    end
  end

  defp validate_plain_string_field(_value, path),
    do: {:error, "'#{path}' must be a plain string value"}

  defp validate_controlled_field_entries(field, values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, index}, :ok ->
      entry_path = "#{path}[#{index}]"

      with :ok <- validate_controlled_entry_shape(entry, entry_path),
           :ok <- validate_controlled_entry_role(field, entry, entry_path) do
        {:cont, :ok}
      else
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp validate_controlled_field_entries(_field, _values, path),
    do: {:error, "'#{path}' must be an array of controlled-term entries"}

  defp validate_controlled_entry_shape(entry, path) when is_map(entry) do
    case map_value(entry, :term) do
      term when is_map(term) ->
        case map_value(term, :id) do
          id when is_binary(id) and byte_size(id) > 0 ->
            :ok

          _ ->
            {:error, "'#{path}.term.id' must be a non-empty string"}
        end

      _ ->
        {:error, "'#{path}.term' must be an object with an 'id' string"}
    end
  end

  defp validate_controlled_entry_shape(_entry, path),
    do: {:error, "'#{path}' must be an object containing at least a term.id"}

  defp validate_controlled_entry_role(field, entry, path) do
    role = map_value(entry, :role)

    cond do
      role_required_field?(field) and is_nil(role) ->
        {:error, "'#{path}.role' is required for #{field}"}

      role_optional_field?(field) and is_nil(role) ->
        :ok

      not role_required_field?(field) and
        not role_optional_field?(field) and
          not is_nil(role) ->
        {:error, "'#{path}.role' must be omitted for #{field}"}

      is_nil(role) ->
        :ok

      true ->
        with :ok <- validate_coded_object(role, "#{path}.role"),
             :ok <- validate_role_scheme(field, role, "#{path}.role") do
          :ok
        end
    end
  end

  defp validate_role_scheme(field, role, path) do
    expected_scheme =
      case field do
        :subject -> "subject_role"
        :contributor -> "marc_relator"
        _ -> nil
      end

    if is_nil(expected_scheme) do
      :ok
    else
      case map_value(role, :scheme) do
        ^expected_scheme -> :ok
        _ -> {:error, "'#{path}.scheme' must be '#{expected_scheme}' for #{field}"}
      end
    end
  end

  defp validate_nested_coded_entries(:notes, values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, index}, :ok ->
      entry_path = "#{path}[#{index}]"

      with true <- is_map(entry) or {:error, "'#{entry_path}' must be an object"},
           note when is_binary(note) <-
             map_value(entry, :note) || {:error, "'#{entry_path}.note' must be a string"},
           true <-
             byte_size(String.trim(note)) > 0 or
               {:error, "'#{entry_path}.note' must not be empty"},
           :ok <- validate_coded_object(map_value(entry, :type), "#{entry_path}.type"),
           :ok <-
             validate_coded_scheme(map_value(entry, :type), "note_type", "#{entry_path}.type") do
        {:cont, :ok}
      else
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp validate_nested_coded_entries(:related_url, values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {entry, index}, :ok ->
      entry_path = "#{path}[#{index}]"

      with true <- is_map(entry) or {:error, "'#{entry_path}' must be an object"},
           url when is_binary(url) <-
             map_value(entry, :url) || {:error, "'#{entry_path}.url' must be a string"},
           true <-
             byte_size(String.trim(url)) > 0 or {:error, "'#{entry_path}.url' must not be empty"},
           :ok <- validate_coded_object(map_value(entry, :label), "#{entry_path}.label"),
           :ok <-
             validate_coded_scheme(map_value(entry, :label), "related_url", "#{entry_path}.label") do
        {:cont, :ok}
      else
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp validate_nested_coded_entries(field, values, path) when is_list(values) do
    if nested_coded_field?(field) do
      :ok
    else
      {:error, "'#{path}' must be an array of objects"}
    end
  end

  defp validate_nested_coded_entries(_field, _values, path),
    do: {:error, "'#{path}' must be an array of objects"}

  defp validate_date_field_values(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {value, index}, :ok ->
      if is_binary(value) and byte_size(String.trim(value)) > 0 do
        {:cont, :ok}
      else
        {:halt, {:error, "'#{path}[#{index}]' must be a non-empty EDTF date string"}}
      end
    end)
  end

  defp validate_date_field_values(_values, path),
    do: {:error, "'#{path}' must be an array of EDTF date strings"}

  defp validate_coded_object(value, path) when is_map(value) do
    case {map_value(value, :id), map_value(value, :scheme)} do
      {id, scheme} when is_binary(id) and is_binary(scheme) and id != "" and scheme != "" ->
        :ok

      _ ->
        {:error, "'#{path}' must contain non-empty string id and scheme"}
    end
  end

  defp validate_coded_object(_value, path),
    do: {:error, "'#{path}' must be an object with id and scheme"}

  defp validate_coded_scheme(value, expected_scheme, path) do
    case map_value(value, :scheme) do
      ^expected_scheme -> :ok
      _ -> {:error, "'#{path}.scheme' must be '#{expected_scheme}'"}
    end
  end

  defp json_blob_string?(value) when is_binary(value) do
    case Jason.decode(String.trim(value)) do
      {:ok, decoded} when is_map(decoded) or is_list(decoded) -> true
      _ -> false
    end
  end

  defp metadata_section(section) when is_map(section),
    do: Map.get(section, :descriptive_metadata) || Map.get(section, "descriptive_metadata")

  defp metadata_section(_section), do: nil

  defp map_value(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp map_value(_map, _key), do: nil

  defp field_name(field) when is_atom(field), do: Atom.to_string(field)
  defp field_name(field) when is_binary(field), do: field
  defp field_name(field), do: inspect(field)

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
    case metadata_section(section) do
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
    Enum.reduce_while(coded_fields(), :ok, fn field, :ok ->
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
    Enum.reduce_while(controlled_fields(), :ok, fn field, :ok ->
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
    Enum.reduce_while(nested_coded_fields(), :ok, fn field, :ok ->
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

  defp error_message(%{message: message}) when is_binary(message), do: message
  defp error_message(%_{} = exception), do: Exception.message(exception)
  defp error_message(message) when is_binary(message), do: message
  defp error_message(other), do: inspect(other)

  defp allowed_descriptive_field?(field), do: field in allowed_descriptive_fields()

  defp allowed_descriptive_fields do
    (editable_descriptive_schema_fields() ++ editable_descriptive_embed_fields())
    |> Enum.uniq()
    |> Enum.reject(&(&1 in read_only_descriptive_metadata_fields()))
  end

  defp read_only_descriptive_metadata_fields do
    [
      :ark,
      :box_name,
      :box_number,
      :folder_name,
      :folder_number,
      :identifier,
      :legacy_identifier,
      :terms_of_use,
      :physical_description_material,
      :physical_description_size,
      :provenance,
      :publisher,
      :related_material,
      :rights_holder,
      :scope_and_contents,
      :series,
      :source,
      :table_of_contents,
      :inserted_at,
      :updated_at
    ]
  end

  defp editable_descriptive_schema_fields, do: WorkDescriptiveMetadata.permitted()
  defp editable_descriptive_embed_fields, do: WorkDescriptiveMetadata.__schema__(:embeds)

  defp controlled_fields, do: editable_descriptive_embed_fields() -- nested_coded_fields()

  defp coded_fields do
    editable_descriptive_schema_fields()
    |> Enum.filter(&(WorkDescriptiveMetadata.__schema__(:type, &1) == Types.CodedTerm))
  end

  defp replace_only_fields do
    coded_fields() ++ single_value_string_fields()
  end

  defp single_value_string_fields do
    editable_descriptive_schema_fields()
    |> Enum.filter(&(WorkDescriptiveMetadata.__schema__(:type, &1) == :string))
  end

  defp date_fields do
    editable_descriptive_schema_fields()
    |> Enum.filter(&(WorkDescriptiveMetadata.__schema__(:type, &1) == {:array, Types.EDTFDate}))
  end

  defp role_required_fields do
    ~w(subject contributor)a
  end

  defp nested_coded_fields do
    ~w(notes related_url)a
  end

  defp role_optional_fields, do: []

  defp controlled_field?(field), do: field in controlled_fields()
  defp coded_field?(field), do: field in coded_fields()
  defp replace_only_field?(field), do: field in replace_only_fields()
  defp single_value_string_field?(field), do: field in single_value_string_fields()
  defp nested_coded_field?(field), do: field in nested_coded_fields()
  defp date_field?(field), do: field in date_fields()
  defp role_required_field?(field), do: field in role_required_fields()
  defp role_optional_field?(field), do: field in role_optional_fields()
end
