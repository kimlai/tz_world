defmodule TzWorldTest do
  use ExUnit.Case
  doctest TzWorld

  test "a known lookup" do
    assert TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}}) ==
             {:ok, "Europe/Paris"}
  end

  test "a known lookup failure" do
    assert TzWorld.timezone_at(%Geo.Point{coordinates: {1.3, 65.62}}) ==
             {:error, :timezone_not_found}
  end

  test "an eastern long, northern lat" do
    assert TzWorld.timezone_at(%Geo.Point{coordinates: {103.8198, 1.3521}}) ==
             {:ok, "Asia/Singapore"}
  end
end
