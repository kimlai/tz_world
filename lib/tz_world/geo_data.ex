defmodule TzWorld.GeoData do
  @moduledoc false

  @compressed_data_file "timezones-geodata.etf.zip"
  @etf_data_file "timezones-geodata.etf"
  @default_data_dir "./priv"

  defdelegate version, to: TzWorld

  def default_data_dir do
    @default_data_dir
  end

  def compressed_data_path do
    Application.get_env(:tz_world, :data_dir, default_data_dir())
    |> Path.join(@compressed_data_file)
    |> to_charlist
  end

  def etf_data_path do
    Application.get_env(:tz_world, :data_dir, default_data_dir())
    |> Path.join(@etf_data_file)
    |> to_charlist
  end

  def generate_compressed_data(source_data, version) do
    geo_json = transform_source_data(source_data, version)
    binary_data = :erlang.term_to_binary(geo_json)
    :zip.zip(compressed_data_path(), [{etf_data_path(), binary_data}])
  end

  def load_compressed_data do
    with {:ok, [{_, terms} | _rest]} <- :zip.unzip(compressed_data_path(), [:memory]) do
      {:ok, :erlang.binary_to_term(terms)}
    end
  end

  def transform_source_data(source_data, version) do
    {:ok, [{_, json} | _rest]} = :zip.unzip(source_data, [:memory])

    json
    |> Jason.decode!()
    |> Geo.JSON.decode!()
    |> Map.get(:geometries)
    |> Enum.map(&update_map_keys/1)
    |> Enum.map(&calculate_bounding_box/1)
    |> List.insert_at(0, version)
  end

  defp update_map_keys(%{properties: properties} = poly) do
    properties =
      Enum.map(properties, fn
        {"tzid", v} -> {:tzid, v}
        other -> other
      end)
      |> Map.new()

    %{poly | properties: properties, srid: 3857}
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
    %Geo.Polygon{coordinates: [bounding_box], srid: 3857}
  end
end
