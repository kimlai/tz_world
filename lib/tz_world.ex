defmodule TzWorld do
  @moduledoc """
  Resolve a timezone name from coordinates.
  """
  use GenServer
  alias :math, as: Math
  alias Geo.Point

  @data_archive Application.app_dir(:tz_world, "priv/timezones-data.zip")

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_state) do
    Process.send_after(self(), :init_state, 0)
    {:ok, []}
  end

  @doc """
  Returns the timezone name for the given coordinates.

  ## Examples

      iex(1)> TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
      "Europe/Paris"

  The algorithm starts by filtering out timezones whose bounding box does not contain
  the given point.
  Once filtered, we return the first timezone which contains the given point, or `nil` if
  none of the timzones match.
  """
  @spec timezone_at(Geo.Point.t) :: String.t | nil
  def timezone_at(%Point{} = point) do
    GenServer.call(__MODULE__, {:timezone_at, point})
  end

  def handle_info(:init_state, _state) do
    {:noreply, read_data()}
  end

  defp read_data do
    {:ok, [data_file]} = :zip.unzip(to_charlist(@data_archive))
    data_file
    |> File.read!()
    |> :erlang.binary_to_term()
  end

  def handle_call({:timezone_at, %Geo.Point{} = point}, _from, state) do
    timezone =
      state
      |> Enum.filter(fn({_, _, bounding_box}) -> contains?(bounding_box, point) end)
      |> Enum.find(fn({_, geometry, _}) -> contains?(geometry, point) end)
      |> case do
        {timezone, _, _} ->
          timezone
        nil ->
          nil
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

  defp interior?(ring, {px, py}) do
    ring = for {x, y} <- ring, do: {x - px, y - py}
    crosses = count_crossing(ring)
    rem(crosses, 2) == 1
  end

  defp disjoint?(rings, point) do
    Enum.all?(rings, fn(ring) -> !interior?(ring, point) end)
  end

  defp count_crossing([_]), do: 0
  defp count_crossing([{ax, ay}, {bx, by} | rest]) do
    crosses = count_crossing([{bx, by} | rest])

    if ((ay > 0) != (by > 0)) && (ax * by - bx * ay) / (by - ay) > 0 do
      crosses + 1
    else
      crosses
    end
  end
end
