defmodule TzWorld.Backend.Ets do
  @moduledoc false

  @behaviour TzWorld.Backend

  use GenServer

  alias Geo.Point

  @timeout 10_000
  @tz_world_version :tz_world_version

  @doc false
  @options [:named_table, :compressed, read_concurrency: true]
  def start_link(options \\ @options) do
    options = if options == [], do: @options, else: options
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @doc false
  def stop(reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(__MODULE__, reason, timeout)
  end

  @doc false
  def init(options) do
    {:ok, [], {:continue, {:load_data, options}}}
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
  def select_candidates(%{coordinates: {lng, lat}}) do
    :ets.select(__MODULE__, TzWorld.Backend.Dets.match_spec(lng, lat))
  end

  @doc false
  @spec reload_timezone_data :: {:ok, term}
  def reload_timezone_data do
    GenServer.call(__MODULE__, :reload_data, @timeout)
  end

  @doc false
  def load_geodata do
    {:ok, t} = TzWorld.Backend.Dets.get_geodata_table()
    __MODULE__ = :dets.to_ets(t, __MODULE__)
  end

  # --- Server callback implementation

  @doc false
  def handle_continue({:load_data, options}, _state) do
    __MODULE__ = :ets.new(__MODULE__, options)
    {:noreply, load_geodata()}
  end

  @doc false
  def handle_call({:timezone_at, %Geo.Point{} = point}, _from, state) do
    {:reply, find_zone(point), state}
  end

  @doc false
  def handle_call({:all_timezones_at, %Geo.Point{} = point}, _from, state) do
    {:reply, find_zones(point), state}
  end

  @doc false
  def handle_call(:version, _from, state) do
    [{_, version}] = :ets.lookup(__MODULE__, @tz_world_version)
    {:reply, {:ok, version}, state}
  end

  @doc false
  def handle_call(:reload_data, _from, _state) do
    {:noreply, {:ok, load_geodata()}}
  end

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

end
