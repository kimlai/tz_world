defmodule TzWorld.Backend do
  @type lat :: -90..90
  @type lng :: -180..180
  @type geo :: Geo.Point.t()

  @callback timezone_at(geo) :: {:ok, term} | {:error, String.t()}
  @callback reload_timezone_data :: :ok
end
