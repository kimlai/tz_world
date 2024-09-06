defmodule TzWorld.GeoData do
  @moduledoc false

  @compressed_data_file "timezones-geodata.etf.zip"
  @etf_data_file "timezones-geodata.etf"
  @osm_srid 3857

  defdelegate version, to: TzWorld
  import TzWorld, only: [maybe_log: 2]

  def default_data_dir do
    TzWorld.app_name()
    |> :code.priv_dir
    |> List.to_string
  end

  def data_dir do
    Application.get_env(TzWorld.app_name(), :data_dir, default_data_dir())
  end

  def compressed_data_path do
    data_dir()
    |> Path.join(@compressed_data_file)
    |> to_charlist
  end

  def etf_data_path do
    data_dir()
    |> Path.join(@etf_data_file)
    |> to_charlist
  end

  def generate_compressed_data(source_data, version, trace? \\ false) when is_list(source_data) do
    maybe_log("Transforming source data", trace?)
    binary_data = transform_source_data(source_data, version)
    maybe_log("Transformed source data", trace?)
    :erlang.garbage_collect()
    :zip.zip(compressed_data_path(), [{etf_data_path(), binary_data}])
    maybe_log("Compressed data into a zip file", trace?)
  end

  def load_compressed_data do
    with {:ok, [{_, terms} | _rest]} <- :zip.unzip(compressed_data_path(), [:memory]) do
      {:ok, :erlang.binary_to_term(terms)}
    end
  end

  def transform_source_data(source_data, version) when is_list(source_data) do
    source_data
    |> :erlang.list_to_binary
    |> transform_source_data(version)
  end

  def transform_source_data(source_data, version) when is_binary(source_data) do
    case :zip.unzip(source_data, [:memory]) do
      {:ok, [{_, json} | _rest]} ->
        json
        |> decode_json(version)
        |> :erlang.term_to_binary()

      error ->
        raise RuntimeError, "Unable to unzip downloaded data. Error: #{inspect error}"
    end
  end

  defp decode_json(json, version) do
    json
    |> json_decode!()
    |> Geo.JSON.decode!()
    |> Map.fetch!(:geometries)
    |> Enum.map(&update_map_keys/1)
    |> Enum.map(&calculate_bounding_box/1)
    |> List.insert_at(0, version)
  end

  defp json_decode!(string) do
    # {json, :ok, ""} = :json.decode(string, :ok, %{null: nil})
    Jason.decode!(string)
  end

  defp update_map_keys(%{properties: properties} = poly) do
    properties =
      Enum.map(properties, fn
        {"tzid", v} -> {:tzid, v}
        other -> other
      end)
      |> Map.new()

    %{poly | properties: properties, srid: @osm_srid}
  end

  defp calculate_bounding_box(
         %Geo.Polygon{coordinates: [polygon | _holes], properties: properties} = poly
       ) do
    properties = Map.put(properties, :bounding_box, calculate_bounding_box(polygon))

    %{poly | properties: properties}
  end

  defp calculate_bounding_box(
         %Geo.MultiPolygon{coordinates: polygons, properties: properties} = poly
       ) do

    bounding_boxes = Enum.map(polygons, &calculate_bounding_box/1)
    properties = Map.put(properties, :bounding_box, bounding_boxes)

    %{poly | properties: properties}
  end

  defp calculate_bounding_box([polygon | _holes]) when is_list(polygon) do
    calculate_bounding_box(polygon)
  end

  defp calculate_bounding_box(polygon) when is_list(polygon) do
    [{x_min, y_min}, {x_max, y_max}] =
      Enum.reduce(polygon, [{180, 90}, {-180, -90}], fn
        {x, y}, [{x_min, y_min}, {x_max, y_max}] ->
          x_min = min(x, x_min)
          y_min = min(y, y_min)
          x_max = max(x, x_max)
          y_max = max(y, y_max)

          [{x_min, y_min}, {x_max, y_max}]
      end)

    bounding_box = [{x_min, y_max}, {x_min, y_min}, {x_max, y_min}, {x_max, y_max}]
    %Geo.Polygon{coordinates: [bounding_box], srid: @osm_srid}
  end
end
