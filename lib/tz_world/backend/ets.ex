defmodule TzWorld.Backend.Ets do
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

  def init(options) do
    {:ok, [], {:continue, {:load_data, options}}}
  end

  def version do
    GenServer.call(__MODULE__, :version, @timeout)
  end

  @doc """
  Returns the timezone name for the given coordinates specified
  as either a `Geo.Point` or as `lng` and `lat` parameters

  ## Examples

      iex> TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
      {:ok, "Europe/Paris"}

      iex> TzWorld.timezone_at(3.2, 45.32)
      {:ok, "Europe/Paris"}


  The algorithm starts by filtering out timezones whose bounding
  box does not contain the given point.

  Once filtered, the first timezone which contains the given
  point is returned, or `nil` if none of the timezones match.

  """
  @spec timezone_at(Geo.Point.t()) :: {:ok, String.t()} | {:error, String.t()}
  def timezone_at(%Point{} = point) do
    find_zone(point)
  end

  def find_zone(%Geo.Point{} = point) do
    point
    |> select_candidates()
    |> Enum.find(&TzWorld.contains?(&1, point))
    |> case do
      %Geo.MultiPolygon{properties: %{tzid: tzid}} -> {:ok, tzid}
      %Geo.Polygon{properties: %{tzid: tzid}} -> {:ok, tzid}
      nil -> {:error, :time_zone_not_found}
    end
  end

  def select_candidates(%{coordinates: {lng, lat}}) do
    :ets.select(__MODULE__, TzWorld.Backend.Dets.match_spec(lng, lat))
  end

  @doc """
  Reload the timezone geo JSON data.

  This allows for the data to be reloaded,
  typically with a new release, without
  restarting the application.

  """
  @spec reload_timezone_data :: :ok
  def reload_timezone_data do
    GenServer.call(__MODULE__, :reload_data, @timeout)
  end

  def load_geodata do
    {:ok, t} = TzWorld.Backend.Dets.get_geodata_table()
    :dets.to_ets(t, __MODULE__)
  end

  # --- Server callback implementation

  def handle_continue({:load_data, options}, _state) do
    __MODULE__ = :ets.new(__MODULE__, options)
    {:noreply, load_geodata()}
  end

  def handle_call(:version, _from, state) do
    [{_, version}] = :ets.lookup(__MODULE__, @tz_world_version)
    {:reply, version, state}
  end

  def handle_call(:reload_data, _from, _state) do
    {:noreply, load_geodata()}
  end

end