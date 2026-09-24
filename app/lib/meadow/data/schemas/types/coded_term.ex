defmodule Meadow.Data.Types.CodedTerm do
  @moduledoc """
  Ecto type for coded terms (values drawn from the `coded_terms` table).

  Declared with a scheme, the column stores only the term id as text and the
  scheme is fixed by the field:

      field :visibility, Types.CodedTerm, scheme: "visibility"

  Values load as `%{id, scheme, label}` so callers keep reading `.label`.
  Declared without a scheme (legacy jsonb embeds), the value is stored as a
  `%{id, scheme}` map and the scheme travels with the value.
  """

  use Ecto.ParameterizedType
  alias Meadow.Data.{CodedTerms, Schemas}

  @impl true
  def init(opts) do
    case {Keyword.get(opts, :scheme), Keyword.get(opts, :schemes)} do
      {nil, nil} ->
        %{scheme: nil, schemes: nil}

      {nil, schemes} when is_list(schemes) ->
        %{scheme: nil, schemes: Enum.map(schemes, &normalize_scheme/1)}

      {scheme, _} ->
        %{scheme: normalize_scheme(scheme), schemes: nil}
    end
  end

  defp normalize_scheme(scheme), do: scheme |> to_string() |> String.downcase()

  @impl true
  def type(%{scheme: nil, schemes: nil}), do: :map
  def type(_params), do: :string

  @impl true
  def embed_as(_format, _params), do: :dump

  @impl true
  def cast(term, params), do: retrieve_term(term, params)

  @impl true
  def load(nil, _loader, _params), do: {:ok, nil}

  def load(id, _loader, %{scheme: scheme}) when is_binary(id) and is_binary(scheme),
    do: retrieve_term(%{id: id, scheme: scheme}, %{scheme: scheme})

  def load(id, _loader, %{schemes: schemes} = params) when is_binary(id) and is_list(schemes),
    do: retrieve_term(%{id: id}, params)

  def load(term, _loader, params), do: retrieve_term(term, params)

  @impl true
  def dump(nil, _dumper, _params), do: {:ok, nil}

  def dump(term, _dumper, %{scheme: nil, schemes: nil}) do
    case id_and_scheme(term) do
      {id, scheme} when is_binary(id) and is_binary(scheme) -> {:ok, %{id: id, scheme: scheme}}
      _ -> :error
    end
  end

  def dump(term, _dumper, _params) do
    case id_and_scheme(term) do
      {id, _} when is_binary(id) -> {:ok, id}
      _ -> :error
    end
  end

  @doc "True if `type` (as returned by `__schema__(:type, field)`) is a CodedTerm"
  def coded_term_type?({:parameterized, {__MODULE__, _}}), do: true
  def coded_term_type?({:parameterized, __MODULE__, _}), do: true
  def coded_term_type?(__MODULE__), do: true
  def coded_term_type?(_), do: false

  @doc "The scheme a schema field is declared with, or nil"
  def scheme_for({:parameterized, {__MODULE__, %{scheme: scheme}}}), do: scheme
  def scheme_for({:parameterized, __MODULE__, %{scheme: scheme}}), do: scheme
  def scheme_for(_), do: nil

  @doc "The list of schemes a field declared with `schemes:` accepts, or nil"
  def schemes_for({:parameterized, {__MODULE__, %{schemes: schemes}}}), do: schemes
  def schemes_for({:parameterized, __MODULE__, %{schemes: schemes}}), do: schemes
  def schemes_for(_), do: nil

  def from_string(value), do: %{id: value}

  defp id_and_scheme(%Schemas.CodedTerm{id: id, scheme: scheme}), do: {id, scheme}
  defp id_and_scheme(%{id: id, scheme: scheme}), do: {id, scheme}
  defp id_and_scheme(%{"id" => id, "scheme" => scheme}), do: {id, scheme}
  defp id_and_scheme(%{id: id}), do: {id, nil}
  defp id_and_scheme(%{"id" => id}), do: {id, nil}
  defp id_and_scheme(id) when is_binary(id), do: {id, nil}
  defp id_and_scheme(_), do: :error

  defp retrieve_term(nil, _params), do: {:ok, nil}

  defp retrieve_term(%{id: "", scheme: _scheme}, _params),
    do: {:error, message: "cannot have a blank id"}

  defp retrieve_term(%{"id" => id, "scheme" => scheme}, params),
    do: retrieve_term(%{id: id, scheme: scheme}, params)

  defp retrieve_term(%{"id" => id}, params), do: retrieve_term(%{id: id}, params)

  defp retrieve_term(%{id: id, scheme: scheme}, %{schemes: schemes}) when is_list(schemes) do
    cond do
      is_nil(scheme) ->
        lookup_any(id, schemes)

      normalize_scheme(scheme) in schemes ->
        lookup(id, normalize_scheme(scheme))

      true ->
        {:error,
         message: "has scheme #{scheme} but field requires one of #{Enum.join(schemes, ", ")}"}
    end
  end

  defp retrieve_term(%{id: id}, %{schemes: schemes}) when is_list(schemes),
    do: lookup_any(id, schemes)

  defp retrieve_term(id, %{schemes: schemes}) when is_binary(id) and is_list(schemes),
    do: lookup_any(id, schemes)

  defp retrieve_term(%{id: id, scheme: scheme}, %{scheme: field_scheme})
       when is_binary(field_scheme) do
    if is_nil(scheme) or String.downcase(to_string(scheme)) == field_scheme,
      do: lookup(id, field_scheme),
      else: {:error, message: "has scheme #{scheme} but field requires #{field_scheme}"}
  end

  defp retrieve_term(%{id: id, scheme: scheme}, _params), do: lookup(id, scheme)

  defp retrieve_term(%{id: id}, %{scheme: field_scheme}) when is_binary(field_scheme),
    do: lookup(id, field_scheme)

  defp retrieve_term(id, %{scheme: field_scheme}) when is_binary(id) and is_binary(field_scheme),
    do: lookup(id, field_scheme)

  defp retrieve_term(%{}, _params), do: {:ok, nil}

  defp retrieve_term(_, _params), do: {:error, message: "is invalid"}

  defp lookup("", _scheme), do: {:error, message: "cannot have a blank id"}

  defp lookup(id, scheme) do
    case CodedTerms.get_coded_term(id, scheme) do
      nil ->
        {:error,
         message: "is an invalid coded term for scheme #{String.upcase(to_string(scheme))}"}

      {{:ok, _}, %{id: id, scheme: scheme, label: label}} ->
        {:ok, %{id: id, scheme: scheme, label: label}}

      other ->
        {:error, other}
    end
  end

  # Try each scheme in turn; the first hit wins
  defp lookup_any("", _schemes), do: {:error, message: "cannot have a blank id"}

  defp lookup_any(id, schemes) do
    Enum.find_value(schemes, fn scheme ->
      case lookup(id, scheme) do
        {:ok, term} -> {:ok, term}
        _ -> nil
      end
    end) ||
      {:error,
       message:
         "is an invalid coded term for schemes #{Enum.map_join(schemes, ", ", &String.upcase/1)}"}
  end
end
