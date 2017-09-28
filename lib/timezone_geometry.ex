defmodule TzWorld.TimezoneGeometry do
  @moduledoc """
  Simple `Ecto` schema to represent a timezone and its associated Geometry.
  """
  use Ecto.Schema

  alias Geo.Geometry

  schema "timezone_geometries" do
    field :timezone, :string
    field :geometry, Geometry
  end
end
