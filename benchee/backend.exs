point = %Geo.Point{coordinates: {3.2, 45.32}}

Benchee.run(
  %{
    "Backend Memory" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.Memory) end,
    "Backend Ets" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.Ets) end,
    "Backend Dets" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.Dets) end,
  },
  time: 10,
  memory_time: 2
)