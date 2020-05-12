defmodule TzWorld.Backend do
  @moduledoc """
  Defines the callbacks for the TzWorld.Backend
  behaviour

  """
  @typedoc "Latitude in degrees"
  @type lat :: -90..90

  @typedoc "Longitude in degrees"
  @type lng :: -180..180

  @typedoc "A point"
  @type geo :: Geo.Point.t()

  @doc """
  Returns the time zone at a specified point
  """
  @callback timezone_at(geo) :: {:ok, String.t()} | {:error, atom}

  @doc """
  Returns all timezones at a specified point
  """
  @callback all_timezones_at(Geo.Point.t()) :: {:ok, [String.t()]} | {:error, atom}

  @doc """
  Reloads the (potentially updated) timezone data
  """
  @callback reload_timezone_data :: {:ok, term}

end
