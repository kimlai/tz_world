defmodule TzWorld.Backend.Dets do
  @moduledoc false

  @behaviour TzWorld.Backend

  use GenServer

  alias Geo.Point

  @timeout 10_000
  @tz_world_version :tz_world_version

  @doc false
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @doc false
  def init(_state) do
    {:ok, [], {:continue, :open_dets_file}}
  end

  @doc false
  def version do
    GenServer.call(__MODULE__, :version, @timeout)
  end

  @doc false
  @spec timezone_at(Geo.Point.t()) :: {:ok, String.t()} | {:error, atom}
  def timezone_at(%Point{} = point) do
    GenServer.call(__MODULE__, {:timezone_at, point}, @timeout)
  end

  @doc false
  @spec all_timezones_at(Geo.Point.t()) :: {:ok, [String.t()]} | {:error, atom}
  def all_timezones_at(%Point{} = point) do
    GenServer.call(__MODULE__, {:all_timezones_at, point}, @timeout)
  end

  @doc false
  @spec reload_timezone_data :: {:ok, term}
  def reload_timezone_data do
    GenServer.call(__MODULE__, :reload_data, @timeout * 3)
  end

  # --- Server callback implementation

  @doc false
  def handle_continue(:open_dets_file, _state) do
    case get_geodata_table() do
     {:error, {:file_error, _, :enoent}} ->
       {:noreply, {:error, :enoent}}
     {:error, {:not_closed, _path}} ->
       raise "NOT CLOSED"
     {:ok, __MODULE__} ->
       {:noreply, {:ok, __MODULE__}}
    end
  end

  @doc false
  def handle_call({:timezone_at, _}, _from, {:error, :enoent} = state) do
    {:reply, state, state}
  end

  def handle_call({:timezone_at, %Geo.Point{} = point}, _from, state) do
    {:reply, find_zone(point), state}
  end

  @doc false
  def handle_call({:all_timezones_at, _point}, _from, {:error, :enoent} = state) do
    {:reply, state, state}
  end

  def handle_call({:all_timezones_at, %Geo.Point{} = point}, _from, state) do
    {:reply, find_zones(point), state}
  end

  @doc false
  def handle_call(:version, _from, {:error, :enoent} = state) do
    {:reply, state, state}
  end

  def handle_call(:version, _from, state) do
    [{_, version}] = :dets.lookup(__MODULE__, @tz_world_version)
    {:reply, {:ok, version}, state}
  end

  @doc false
  def handle_call(:reload_data, _from, {:error, :enoent}) do
    :ok = save_dets_geodata()
    {:reply, get_geodata_table(), get_geodata_table()}
  end

  def handle_call(:reload_data, _from, _state) do
    :dets.close(__MODULE__)
    :ok = save_dets_geodata()
    {:reply, get_geodata_table(), get_geodata_table()}
  end

  # --- Helpers

  @doc false
  defp find_zones(%Geo.Point{} = point) do
    point
    |> select_candidates()
    |> Enum.filter(&TzWorld.contains?(&1, point))
    |> Enum.map(&(&1.properties.tzid))
    |> wrap(:ok)
  end

  defp wrap(term, atom) do
    {atom, term}
  end

  @doc false
  defp find_zone(%Geo.Point{} = point) do
    point
    |> select_candidates()
    |> Enum.find(&TzWorld.contains?(&1, point))
    |> case do
      %Geo.MultiPolygon{properties: %{tzid: tzid}} -> {:ok, tzid}
      %Geo.Polygon{properties: %{tzid: tzid}} -> {:ok, tzid}
      nil -> {:error, :time_zone_not_found}
    end
  end

  defp select_candidates(%{coordinates: {lng, lat}}) do
    :dets.select(__MODULE__, match_spec(lng, lat))
  end

  @doc false
  def match_spec(lng, lat) do
    [
      {
        {{:"$1", :"$2", :"$3", :"$4"}, :"$5"},
        [
          {:andalso, {:andalso, {:>=, lng, :"$1"}, {:"=<", lng, :"$2"}},
           {:andalso, {:>=, lat, :"$3"}, {:"=<", lat, :"$4"}}}
        ],
        [:"$5"]
      }
    ]
  end

  @doc false
  def filename do
    TzWorld.GeoData.data_dir()
    |> Path.join("timezones-geodata.dets")
    |> String.to_charlist()
  end

  @doc false
  def save_dets_geodata do
    dets_options = Keyword.put(dets_options(), :access, :read_write)

    {:ok, __MODULE__} = :dets.open_file(__MODULE__, dets_options)
    :ok = :dets.delete_all_objects(__MODULE__)

    {:ok, geodata} = TzWorld.GeoData.load_compressed_data()
    [version | shapes] = geodata

    for shape <- shapes do
      add_to_dets(__MODULE__, shape)
    end

    :ok = :dets.insert(__MODULE__, {@tz_world_version, version})
    :dets.close(__MODULE__)
  end

  defp add_to_dets(t, shape) do
    case shape.properties.bounding_box do
      %Geo.Polygon{} = box ->
        [[{x_min, y_max}, {_, y_min}, {x_max, _}, _]] = box.coordinates
        :dets.insert(t, {{x_min, x_max, y_min, y_max}, shape})

      polygons when is_list(polygons) ->
        for box <- polygons do
          [[{x_min, y_max}, {_, y_min}, {x_max, _}, _]] = box.coordinates
          :dets.insert(t, {{x_min, x_max, y_min, y_max}, shape})
        end
    end
  end

  @doc false
  def get_geodata_table do
    :dets.open_file(__MODULE__, dets_options())
  end

  @slots 1_000

  @doc false
  defp dets_options do
    [file: filename(), access: :read, estimated_no_objects: @slots]
  end

end
