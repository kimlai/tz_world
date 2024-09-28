defmodule TzWorld.Backend.DetsWithIndexCache do
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
  def stop(reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(__MODULE__, reason, timeout)
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

  @doc false
  def filename do
    TzWorld.Backend.Dets.filename()
  end

  @slots 800
  defp dets_options do
    [file: filename(), access: :read, estimated_no_objects: @slots]
  end

  @doc false
  def get_geodata_table do
    :dets.open_file(__MODULE__, dets_options())
  end

  @doc false
  def save_dets_geodata do
    dets_options = Keyword.put(dets_options(), :access, :read_write)

    {:ok, t} = :dets.open_file(__MODULE__, dets_options)
    :ok = :dets.delete_all_objects(t)

    {:ok, geodata} = TzWorld.GeoData.load_compressed_data()
    [version | shapes] = geodata

    for shape <- shapes do
      add_to_dets(t, shape)
    end

    :ok = :dets.insert(t, {@tz_world_version, version})
    :dets.close(t)
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

  # --- Server callback implementation

  @doc false
  def handle_continue(:open_dets_file, _state) do
    case get_geodata_table() do
      {:error, {:file_error, _, :enoent}} ->
        {:noreply, {:error, :enoent}}

      {:ok, __MODULE__} ->
        {:noreply, get_index_cache()}
    end
  end

  @doc false
  def handle_call({:timezone_at, _}, _from, {:error, :enoent} = state) do
    {:reply, state, state}
  end

  def handle_call({:timezone_at, %Geo.Point{} = point}, _from, state) do
    {:reply, find_zone(point, state), state}
  end

  def handle_call({:all_timezones_at, _point}, _from, {:error, :enoent} = state) do
    {:reply, state, state}
  end

  def handle_call({:all_timezones_at, %Geo.Point{} = point}, _from, state) do
    {:reply, find_zones(point, state), state}
  end

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
    {:reply, get_geodata_table(), get_index_cache()}
  end

  def handle_call(:reload_data, _from, _state) do
    :dets.close(__MODULE__)
    :ok = save_dets_geodata()
    {:reply, get_geodata_table(), get_index_cache()}
  end

  @doc false
  defp find_zone(%Geo.Point{} = point, state) do
    point
    |> select_candidates(state)
    |> Enum.find(&TzWorld.contains?(&1, point))
    |> case do
      %Geo.MultiPolygon{properties: %{tzid: tzid}} -> {:ok, tzid}
      %Geo.Polygon{properties: %{tzid: tzid}} -> {:ok, tzid}
      nil -> {:error, :time_zone_not_found}
    end
  end

  @doc false
  defp find_zones(%Geo.Point{} = point, state) do
    point
    |> select_candidates(state)
    |> Enum.filter(&TzWorld.contains?(&1, point))
    |> Enum.map(& &1.properties.tzid)
    |> wrap(:ok)
  end

  defp wrap(term, atom) do
    {atom, term}
  end

  defp select_candidates(%{coordinates: {lng, lat}}, state) do
    Enum.filter(state, fn {x_min, x_max, y_min, y_max} ->
      lng >= x_min && lng <= x_max && lat >= y_min && lat <= y_max
    end)
    |> Enum.map(fn bounding_box ->
      [{_key, value}] = :dets.lookup(__MODULE__, bounding_box)
      value
    end)
  end

  def get_index_cache do
    :dets.select(__MODULE__, index_spec())
  end

  def index_spec do
    [{{{:"$1", :"$2", :"$3", :"$4"}, :"$5"}, [], [{{:"$1", :"$2", :"$3", :"$4"}}]}]
  end
end
