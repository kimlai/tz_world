defmodule TzWorld do
  @moduledoc """
  The main module of TzWorld.
  """
  import Ecto.Query, warn: false

  @doc """
  Returns the timezone name for the given coordinates.

  It issues an SQL query using `Ecto`.

  ## Examples

      iex(2)> TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
      [debug] QUERY OK source="timezone_geometries" db=58.2ms queue=0.1ms
      SELECT t0."timezone" FROM "timezone_geometries" AS t0 WHERE (ST_Contains(geometry, ST_Point($1, $2)) = TRUE) [3.2, 45.32]
      "Europe/Paris"
  """
  @spec timezone_at(Geo.Point.t) :: String.t | nil
  def timezone_at(%Geo.Point{coordinates: {lng, lat}}) do
    repo = Application.get_env(:tz_world, :repo)
    "timezone_geometries"
    |> where([tz_g], fragment("ST_Contains(geometry, ST_Point(?, ?))", ^lng, ^lat) == true)
    |> select([tz_g], tz_g.timezone)
    |> repo.one
  end
end
