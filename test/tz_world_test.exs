defmodule TzWorldTest do
  use ExUnit.Case
  doctest TzWorld

  @backends [TzWorld.Backend.Memory, TzWorld.Backend.Dets, TzWorld.Backend.Ets]

  setup_all do
    for backend <- @backends do
      backend.start_link
    end

    :ok
  end

  for backend <- @backends do
    test "a known lookup with backend #{backend}" do
      assert TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}}, unquote(backend)) ==
               {:ok, "Europe/Paris"}
    end

    test "a known lookup failure with backend #{backend}" do
      assert TzWorld.timezone_at(%Geo.Point{coordinates: {1.3, 65.62}}, unquote(backend)) ==
               {:error, :time_zone_not_found}
    end

    test "an eastern lon, northern lat with backend #{backend}" do
      assert TzWorld.timezone_at(%Geo.Point{coordinates: {103.8198, 1.3521}}, unquote(backend)) ==
               {:ok, "Asia/Singapore"}
    end

    test "a western lon, northern lat with GeoPointZ with backend #{backend}" do
      assert TzWorld.timezone_at(
               %Geo.PointZ{coordinates: {-74.006, 40.7128, 0.0}},
               unquote(backend)
             ) ==
               {:ok, "America/New_York"}
    end
  end
end
