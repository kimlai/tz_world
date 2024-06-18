defmodule TzWorld do
  @moduledoc """
  Resolve a timezone name from coordinates.

  """
  alias Geo.{Point, PointZ}
  import TzWorld.Guards

  @type backend :: module()

  @reload_backends [
    TzWorld.Backend.Memory,
    TzWorld.Backend.Dets,
    TzWorld.Backend.DetsWithIndexCache,
    TzWorld.Backend.Ets,
    TzWorld.Backend.EtsWithIndexCache,
  ]

  @doc """
  Returns the OTP app name of :tz_world

  """
  def app_name do
    :tz_world
  end

  @doc """
  Returns the installed version of time
  zone data

  ## Example

      TzWorld.version
      => {:ok, "2020d"}

  """
  @spec version :: {:ok, String.t()} | {:error, :enoent}
  def version do
    fetch_backend().version()
  end

  @doc """
  Reload the timezone geometry data.

  This allows for the data to be reloaded,
  typically with a new release, without
  restarting the application.

  """
  def reload_timezone_data do
    Enum.map(@reload_backends, fn backend -> apply(backend, :reload_timezone_data, []) end)
  end

  @doc """
  Returns the *first* timezone name found for the given
  coordinates specified as either a `Geo.Point`,
  a `Geo.PointZ` or a tuple `{lng, lat}`

  ## Arguments

  * `point` is a `Geo.Point.t()` a `Geo.PointZ.t()` or
    a tuple `{lng, lat}`

  * `backend` is any backend access module.

  ## Returns

  * `{:ok, timezone}` or

  * `{:error, :time_zone_not_found}`

  ## Notes

  Note that the point is always expressed as
  `lng` followed by `lat`.

  ## Examples

      iex> TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
      {:ok, "Europe/Paris"}

      iex> TzWorld.timezone_at({3.2, 45.32})
      {:ok, "Europe/Paris"}

      iex> TzWorld.timezone_at({0.0, 0.0})
      {:error, :time_zone_not_found}


  The algorithm starts by filtering out timezones whose bounding
  box does not contain the given point.

  Once filtered, the *first* timezone which contains the given
  point is returned, or an error tuple if none of the
  timezones match.

  In rare cases, typically due to territorial disputes,
  one or more timezones may apply to a given location.
  This function returns the first time zone that matches.

  """
  @spec timezone_at(Geo.Point.t(), backend) ::
    {:ok, String.t()} | {:error, atom}

  def timezone_at(point, backend \\ fetch_backend())

  def timezone_at(%Point{} = point, backend) when is_atom(backend) do
    backend.timezone_at(point)
  end

  @spec timezone_at(Geo.PointZ.t(), backend) ::
    {:ok, String.t()} | {:error, atom}

  def timezone_at(%PointZ{coordinates: {lng, lat, _alt}}, backend) when is_atom(backend) do
    point = %Point{coordinates: {lng, lat}}
    backend.timezone_at(point)
  end

  @spec timezone_at({lng :: number, lat :: number}, backend) ::
    {:ok, String.t()} | {:error, atom}

  def timezone_at({lng, lat}, backend) when is_lng(lng) and is_lat(lat) do
    point = %Geo.Point{coordinates: {lng, lat}}
    backend.timezone_at(point)
  end

  @doc """
  Returns all timezone name found for the given
  coordinates specified as either a `Geo.Point`,
  a `Geo.PointZ` or a tuple `{lng, lat}`

  ## Arguments

  * `point` is a `Geo.Point.t()` a `Geo.PointZ.t()` or
    a tuple `{lng, lat}`

  * `backend` is any backend access module.

  ## Returns

  * `{:ok, timezone}` or

  * `{:error, :time_zone_not_found}`

  ## Notes

  Note that the point is always expressed as
  `lng` followed by `lat`.

  ## Examples

      iex> TzWorld.all_timezones_at(%Geo.Point{coordinates: {3.2, 45.32}})
      {:ok, ["Europe/Paris"]}

      iex> TzWorld.all_timezones_at({3.2, 45.32})
      {:ok, ["Europe/Paris"]}

      iex> TzWorld.all_timezones_at({0.0, 0.0})
      {:ok, []}


  The algorithm starts by filtering out timezones whose bounding
  box does not contain the given point.

  Once filtered, all timezones which contains the given
  point is returned, or an error tuple if none of the
  timezones match.

  In rare cases, typically due to territorial disputes,
  one or more timezones may apply to a given location.
  This function returns all time zones that match.

  """
  @spec all_timezones_at(Geo.Point.t(), backend) ::
    {:ok, [String.t()]}

  def all_timezones_at(point, backend \\ fetch_backend())

  def all_timezones_at(%Point{} = point, backend) when is_atom(backend) do
    backend.all_timezones_at(point)
  end

  @spec all_timezones_at(Geo.PointZ.t(), backend) ::
    {:ok, [String.t()]}

  def all_timezones_at(%PointZ{coordinates: {lng, lat, _alt}}, backend) when is_atom(backend) do
    point = %Point{coordinates: {lng, lat}}
    backend.all_timezones_at(point)
  end

  @spec all_timezones_at({lng :: number, lat :: number}, backend) ::
    {:ok, [String.t()]}

  def all_timezones_at({lng, lat}, backend) when is_lng(lng) and is_lat(lat) do
    point = %Geo.Point{coordinates: {lng, lat}}
    backend.all_timezones_at(point)
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

  @default_backend_precedence [
    TzWorld.Backend.EtsWithIndexCache,
    TzWorld.Backend.Memory,
    TzWorld.Backend.DetsWithIndexCache,
    TzWorld.Backend.Ets,
    TzWorld.Backend.Dets
  ]

  def fetch_backend do
    [Application.get_env(:tz_wprld, :backend) | @default_backend_precedence]
    |> Enum.reject(&is_nil/1)
    |> Enum.find(&Process.whereis/1) ||
      raise(RuntimeError,
        "No TzWorld backend appears to be running. " <>
        "please add one of #{inspect @default_backend_precedence} to your supervision tree"
      )
  end

end
