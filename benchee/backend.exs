point = %Geo.Point{coordinates: {3.2, 45.32}}
TzWorld.Backend.Memory.start_link
TzWorld.Backend.Ets.start_link
TzWorld.Backend.EtsWithIndexCache.start_link
TzWorld.Backend.Dets.start_link
TzWorld.Backend.DetsWithIndexCache.start_link

Benchee.run(
  %{
    "Backend Memory" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.Memory) end,
    "Backend Ets" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.Ets) end,
    "Backend EtsWithIndexCache" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.EtsWithIndexCache) end,
    "Backend Dets" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.Dets) end,
    "Backend DetsWithIndexCache" => fn ->
      TzWorld.timezone_at(point, TzWorld.Backend.DetsWithIndexCache) end,
  },
  time: 10,
  memory_time: 2
)