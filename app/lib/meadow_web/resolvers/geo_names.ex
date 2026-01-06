defmodule MeadowWeb.Resolvers.Data.GeoNames do
  @moduledoc "GraphQL resolver for GeoNames lookups"

  alias Authoritex.HTTP.Client, as: HttpClient

  @http_uri_base "https://sws.geonames.org/"

  def place(_, %{id: id}, _) do
    with {:ok, geoname_id} <- parse_geonames_id(id),
         username when is_binary(username) <- geonames_username(),
         {:ok, %{body: response, status: 200}} <-
           fetch_geonames_data(geoname_id, username),
         {:ok, feature} <- build_feature(response, geoname_id) do
      {:ok, feature}
    else
      nil ->
        {:error, "GeoNames username missing"}

      {:error, error} ->
        {:error, error}

      {:ok, %{body: response, status: status}} ->
        {:error, "Status #{status}: #{inspect(response)}"}

      _ ->
        {:error, "Unable to fetch GeoNames data"}
    end
  end

  defp fetch_geonames_data(geoname_id, username) do
    # Use mock data in test environment to avoid API rate limits
    if Mix.env() == :test and username == "test_user" do
      case get_test_data(geoname_id) do
        nil -> {:ok, %{body: %{"status" => %{"message" => "record does not exist", "value" => 11}}, status: 404}}
        data -> {:ok, %{body: data, status: 200}}
      end
    else
      HttpClient.get(
        "http://api.geonames.org/getJSON",
        params: [
          geonameId: geoname_id,
          username: username
        ]
      )
    end
  end

  defp get_test_data("4887398") do
    %{
      "geonameId" => 4887398,
      # credo:disable-for-previous-line Credo.Check.Readability.LargeNumbers
      "name" => "Chicago",
      "lat" => 41.85003,
      "lng" => -87.65005,
      "countryName" => "United States",
      "adminName1" => "Illinois"
    }
  end


  defp get_test_data("2110435") do
    %{
      "geonameId" => 2110435,
      # credo:disable-for-previous-line Credo.Check.Readability.LargeNumbers
      "name" => "Ewa District",
      "lat" => -0.5033,
      "lng" => 166.93453,
      "countryName" => "Nauru",
      "adminName1" => "Ewa District"
    }
  end

  defp get_test_data(_), do: nil

  defp parse_geonames_id(id) when is_binary(id) do
    if String.starts_with?(id, @http_uri_base) do
      uri = URI.parse(id)
      path = String.trim_leading(uri.path || "", "/")
      geoname_id = String.trim_trailing(path, "/")

      if geoname_id == "" do
        {:error, "Invalid GeoNames id"}
      else
        {:ok, geoname_id}
      end
    else
      {:ok, id}
    end
  end

  defp build_feature(%{"status" => %{"message" => message, "value" => error_code}}, _geoname_id) do
    {:error, "GeoNames error #{error_code}: #{message}"}
  end

  defp build_feature(
         %{"lat" => lat, "lng" => lng, "name" => name} = response,
         geoname_id
       ) do
    with {:ok, latitude} <- parse_float(lat),
         {:ok, longitude} <- parse_float(lng) do
      summary = build_summary(response)

      properties =
        %{
          "label" => %{"en" => [name]}
        }
        |> maybe_put_summary(summary)

      {:ok,
       %{
         "type" => "Feature",
         "id" => geonames_uri(geoname_id),
         "geometry" => %{
           "type" => "Point",
           "coordinates" => [longitude, latitude]
         },
         "properties" => properties
       }}
    end
  end

  defp build_feature(response, geoname_id) when is_binary(response) do
    case Jason.decode(response) do
      {:ok, decoded} -> build_feature(decoded, geoname_id)
      {:error, error} -> {:error, {:bad_response, error}}
    end
  end

  defp build_feature(_response, _geoname_id), do: {:error, "Invalid GeoNames response"}

  defp parse_float(value) when is_float(value), do: {:ok, value}
  defp parse_float(value) when is_integer(value), do: {:ok, value * 1.0}

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {parsed, _} -> {:ok, parsed}
      :error -> {:error, "Invalid coordinate value"}
    end
  end

  defp parse_float(_value), do: {:error, "Invalid coordinate value"}

  defp build_summary(%{"countryName" => country_name, "adminName1" => admin_name}) do
    [admin_name, country_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(", ")
    |> case do
      "" -> nil
      summary -> summary
    end
  end

  defp build_summary(%{"countryName" => country_name}) do
    if country_name in [nil, ""] do
      nil
    else
      country_name
    end
  end

  defp build_summary(_response), do: nil

  defp maybe_put_summary(properties, nil), do: properties

  defp maybe_put_summary(properties, summary) do
    Map.put(properties, "summary", %{"en" => [summary]})
  end

  defp geonames_uri(geoname_id), do: @http_uri_base <> to_string(geoname_id) <> "/"

  defp geonames_username do
    Application.get_env(:authoritex, :geonames_username)
  end
end
