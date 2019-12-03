defmodule TzWorldTest do
  use ExUnit.Case
  doctest TzWorld

  test "a known lookup" do
    assert TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}}) ==
             {:ok, "Europe/Paris"}
  end

  test "a known lookup failure" do
    assert TzWorld.timezone_at(%Geo.Point{coordinates: {1.3, 65.62}}) ==
             {:error, :time_zone_not_found}
  end

  test "an eastern lon, northern lat" do
    assert TzWorld.timezone_at(%Geo.Point{coordinates: {103.8198, 1.3521}}) ==
             {:ok, "Asia/Singapore"}
  end

  test "a western lon, northern lat with GeoPointZ" do
    assert TzWorld.timezone_at(%Geo.PointZ{coordinates: {-74.006, 40.7128, 0.0}}) ==
             {:ok, "America/New_York"}
  end
end
