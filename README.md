# TzWorld

Resolve timezones from a location using data from [this project](https://github.com/evansiroky/timezone-boundary-builder).

## Installation

1. Add `tz_world` to your list of dependencies in `mix.exs`:
```elixir
def deps do
  [
    {:tz_world, "~> 0.1.0"}
  ]
end
```
After adding TzWorld as a dependency, run `mix deps.get` to install it.

## Usage

```elixir
iex(1)> TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
"Europe/Paris"
iex(2)> TzWorld.timezone_at(%Geo.Point{coordinates: {1.3, 65.62}})
nil
```
