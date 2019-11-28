defmodule TzWorld.Guards do
  @moduledoc false

  defguard is_lng(lng) when is_number(lng) and lng >= -180 and lng <= 180
  defguard is_lat(lat) when is_number(lat) and lat >= -90 and lat <= 90
end
