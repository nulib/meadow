defmodule Meadow.Data.Enrichment do
  @moduledoc """
  A module for enriching data objects with additional information, such as labels for controlled terms.
  """
  require Logger
  alias Meadow.Data.{CodedTerms, ControlledTerms}

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)a
  @coded_fields ~w(license rights_statement)a
  # Fields with arrays of objects containing coded terms
  @nested_coded_fields ~w(notes related_url)a

  # Enrichment functions for controlled terms

  def enrich_controlled_terms(attrs) do
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


end
