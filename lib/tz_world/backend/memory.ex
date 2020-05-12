defmodule TzWorld.Backend.Memory do
  @behaviour TzWorld.Backend

  use GenServer

  alias TzWorld.GeoData
  alias Geo.Point

  @timeout 10_000

  @doc false
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @doc false
  def init(_options) do
    {:ok, [], {:continue, :load_data}}
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
    GenServer.call(__MODULE__, :reload_data, @timeout)
  end

  # --- Server callback implementation

  @doc false
  def handle_continue(:load_data, _state) do
    {:ok, tz_data} = GeoData.load_compressed_data()
    {:noreply, tz_data}
  end

  @doc false
  def handle_call(:reload_data, _from, _state) do
    case GeoData.load_compressed_data() do
      {:ok, tz_data} -> {:reply, {:ok, :loaded}, tz_data}
      other -> {:reply, other, other}
    end
  end

  @doc false
  def handle_call(:version, _from, state) do
    [version | _tz_data] = state
    {:reply, {:ok, version}, state}
  end

  @doc false
  def handle_call({:timezone_at, %Geo.Point{} = point}, _from, state) do
    timezone =
      with [_version | tz_data] <- state do
        tz_data
        |> Enum.filter(&TzWorld.contains?(&1.properties.bounding_box, point))
        |> Enum.find(&TzWorld.contains?(&1, point))
        |> case do
          %Geo.MultiPolygon{properties: %{tzid: tzid}} -> {:ok, tzid}
          %Geo.Polygon{properties: %{tzid: tzid}} -> {:ok, tzid}
          nil -> {:error, :time_zone_not_found}
        end
      end

    {:reply, timezone, state}
  end

  @doc false
  def handle_call({:all_timezones_at, %Geo.Point{} = point}, _from, state) do
    timezone =
      with [_version | tz_data] <- state do
        tz_data
        |> Enum.filter(&TzWorld.contains?(&1.properties.bounding_box, point))
        |> Enum.filter(&TzWorld.contains?(&1, point))
        |> Enum.map(&(&1.properties.tzid))
        |> wrap(:ok)
      end

    {:reply, timezone, state}
  end

  defp wrap(term, atom) do
    {atom, term}
  end
end
