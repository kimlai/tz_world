defmodule TzWorld do
  @moduledoc """
  Resolve a timezone name from coordinates.

  """
  alias Geo.{Point, PointZ}
  import TzWorld.Guards

  def version do
    fetch_backend().version()
  end

  @reload_backends [
    TzWorld.Backend.Memory,
    TzWorld.Backend.Dets,
    TzWorld.Backend.DetsWithIndexCache,
    TzWorld.Backend.Ets
  ]

  def reload_timezone_data do
    Enum.map(@reload_backends, fn backend -> apply(backend, :reload_timezone_data, []) end)
  end

  @spec timezone_at(Geo.Point.t()) :: {:ok, String.t()} | {:error, String.t()}
  def timezone_at(point, backend \\ fetch_backend())

  def timezone_at(%Point{} = point, backend) do
    backend.timezone_at(point)
  end

  @spec timezone_at(Geo.PointZ.t()) :: {:ok, String.t()} | {:error, String.t()}
  def timezone_at(%PointZ{coordinates: {lng, lat, _alt}}, backend) do
    point = %Point{coordinates: {lng, lat}}
    backend.timezone_at(point)
  end

  @spec timezone_at(lng :: number, lat :: number) :: {:ok, String.t()} | {:error, String.t()}
  def timezone_at(lng, lat, backend) when is_lng(lng) and is_lat(lat) do
    point = %Geo.Point{coordinates: {lng, lat}}
    backend.timezone_at(point)
  end

  @doc false
  def contains?(%Geo.MultiPolygon{} = multi_polygon, %Geo.Point{} = point) do
    multi_polygon.coordinates
    |> Enum.any?(fn polygon -> contains?(%Geo.Polygon{coordinates: polygon}, point) end)
  end

  def contains?(%Geo.Polygon{coordinates: [envelope | holes]}, %Geo.Point{coordinates: point}) do
    interior?(envelope, point) && disjoint?(holes, point)
  end

  def contains?(bounding_boxes, point) when is_list(bounding_boxes) do
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

  @backend_precedence [
    TzWorld.Backend.Memory,
    TzWorld.Backend.DetsWithIndexCache,
    TzWorld.Backend.Ets,
    TzWorld.Backend.Dets
  ]

  def fetch_backend do
    Enum.find(@backend_precedence, &Process.whereis/1) ||
      raise(RuntimeError, "No TzWorld backend appears to be running")
  end
end
