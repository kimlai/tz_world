defmodule TzWorld do
  @moduledoc """
  Resolve a timezone name from coordinates.

  """
  use GenServer
  alias Geo.{Point, PointZ}
  import TzWorld.Guards
  alias TzWorld.GeoData

  @timeout 10_000

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_state) do
    {:ok, [], {:continue, :load_data}}
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
  point is returned, or `nil` if none of the timzones match.

  """
  @spec timezone_at(Geo.Point.t()) :: {:ok, String.t()} | {:error, String.t()}
  def timezone_at(%Point{} = point) do
    GenServer.call(__MODULE__, {:timezone_at, point}, @timeout)
  end

  @spec timezone_at(Geo.PointZ.t()) :: {:ok, String.t()} | {:error, String.t()}
  def timezone_at(%PointZ{coordinates: {lng, lat, _alt}}) do
    point = %Point{coordinates: {lng, lat}}
    GenServer.call(__MODULE__, {:timezone_at, point}, @timeout)
  end

  @spec timezone_at(lng :: number, lat :: number) :: {:ok, String.t()} | {:error, String.t()}
  def timezone_at(lng, lat) when is_lng(lng) and is_lat(lat) do
    point = %Geo.Point{coordinates: {lng, lat}}
    GenServer.call(__MODULE__, {:timezone_at, point}, @timeout)
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

  # --- Server callback implementation

  def handle_continue(:load_data, _state) do
    {:noreply, GeoData.load_compressed_data()}
  end

  def handle_call(:reload_data, _from, _state) do
    case GeoData.load_compressed_data() do
      {:ok, _data} = return -> {:reply, :ok, return}
      other -> {:reply, other, other}
    end
  end

  def handle_call(:version, _from, state) do
    case state do
      {:ok, [version | _tz_data]} -> {:reply, {:ok, version}, state}
      other -> {:reply, other, state}
    end
  end

  def handle_call({:timezone_at, %Geo.Point{} = point}, _from, state) do
    timezone =
      with {:ok, [_version | tz_data]} <- state do
        tz_data
        |> Enum.filter(fn geometry -> contains?(geometry.properties.bounding_box, point) end)
        |> Enum.find(&contains?(&1, point))
        |> case do
          %Geo.MultiPolygon{properties: %{tzid: tzid}} -> {:ok, tzid}
          %Geo.Polygon{properties: %{tzid: tzid}} -> {:ok, tzid}
          nil -> {:error, :time_zone_not_found}
        end
      end

    {:reply, timezone, state}
  end

  defp contains?(%Geo.MultiPolygon{} = multi_polygon, %Geo.Point{} = point) do
    multi_polygon.coordinates
    |> Enum.any?(fn polygon -> contains?(%Geo.Polygon{coordinates: polygon}, point) end)
  end

  defp contains?(%Geo.Polygon{coordinates: [envelope | holes]}, %Geo.Point{coordinates: point}) do
    interior?(envelope, point) && disjoint?(holes, point)
  end

  defp contains?(bounding_boxes, point) when is_list(bounding_boxes) do
    Enum.any?(bounding_boxes, &contains?(&1, point))
  end

  defp interior?(ring, {px, py}) do
    ring = for {x, y} <- ring, do: {x - px, y - py}
    crosses = count_crossing(ring)
    rem(crosses, 2) == 1
  end

  defp disjoint?(rings, point) do
    Enum.all?(rings, fn ring -> !interior?(ring, point) end)
  end

  defp count_crossing([_]), do: 0

  defp count_crossing([{ax, ay}, {bx, by} | rest]) do
    crosses = count_crossing([{bx, by} | rest])

    if ay > 0 != by > 0 && (ax * by - bx * ay) / (by - ay) > 0 do
      crosses + 1
    else
      crosses
    end
  end
end
