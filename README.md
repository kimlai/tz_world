# TzWorld

Resolve timezones from a location using data from the [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder) project.

## Installation

Add `tz_world` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tz_world, "~> 0.3.0"}
  ]
end
```

After adding TzWorld as a dependency, run `mix deps.get` to install it. Then run `mix tz_world.update` to install the timezone data.

**NOTE** No data is installed with the package and until the data is installed with `mix tz_world.update` all calls to `TzWorld.timezone_at/1` will return `{:error, :noent}`.

## Installing the Timezones Geo JSON data

Installing `tz_world` from source or from hex does not include the timezones geo JSON data. The data is requried and to install or update it run:
```elixir
mix tz_world.update
```
This task will download, transform, zip and store the timezones geo data. Depending on internet and computer speed this may take a few minutes.

### Data location

By default the data will be placed in `./priv/tz_world`.

An alternative location can be configured in `config.exs` as follows:
```elixir
config :tz_world,
  data_dir: "some/directory"
```

### Updating the Timezone data

From time-to-time the timezones geo JSON data is updated in the [upstream project](https://github.com/evansiroky/timezone-boundary-builder/releases). The mix task `mix tz_world.update` will update the data if it is available. This task can be run at any time, it will detect when new data is available and only download it when a new release is available. The generated file `TIMEZONES_GEOJSON_VERSION` is used to track the current installed version of the data.

A running application can also be instructed to reload the data by executing `TzWorld.reload_timezone_data`.

## Usage

The primary API is `TzWorld.timezone_at`. It takes either a `Geo.Point` struct or a `longitude` and `latitude` in degrees. Note the parameter order: `longitude`, `latitude`.

```elixir
iex> TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
{:ok, "Europe/Paris"}

iex> TzWorld.timezone_at(3.2, 45.32)
{:ok, "Europe/Paris"}

iex> TzWorld.timezone_at(%Geo.PointZ{coordinates: {-74.006, 40.7128, 0.0}})
{:ok, "America/New_York"}

iex> TzWorld.timezone_at(%Geo.Point{coordinates: {1.3, 65.62}})
{:error, :time_zone_not_found}
```
