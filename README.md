# TzWorld

[![hex.pm](https://img.shields.io/hexpm/v/tz_world.svg)](https://hex.pm/packages/tz_world)
[![hex.pm](https://img.shields.io/hexpm/dt/tz_world.svg)](https://hex.pm/packages/tz_world)
[![hex.pm](https://img.shields.io/hexpm/l/tz_world.svg)](https://hex.pm/packages/tz_world)
[![github.com](https://img.shields.io/github/last-commit/kimlai/tz_world.svg)](https://github.com/kimlai/tz_world)

Resolve timezones from a location using data from the
[timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder)
project.

## Installation

Add `tz_world` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tz_world, "~> 1.3"}
  ]
end
```

After adding `TzWorld` as a dependency, run `mix deps.get` to install it. Then run `mix tz_world.update` to install the timezone data.

**NOTE** No data is installed with the package and until the data is installed
with `mix tz_world.update` all calls to `TzWorld.timezone_at/1` will return
`{:error, :time_zone_not_found}`.

### Configuration

There is no mandatory configuration required however four options may be configured in `config.exs`:

```elixir
config :tz_world,
  # Configure a custom TzWorld backend. It will be used
  # as the default backend in calls to `TzWorld.timezone_at/1`
  backend: MyTzWorldBackend,
  # The default is the `priv` directory of `:tz_world`
  data_dir: "geodata/directory",
  # The default is either the trust store included in the
  # libraries `CAStore` or `certifi` or the platform
  # trust store.
  cacertfile: "path/to/ca_trust_store",
  # The default is no options, however one can set any `httpc` client options.
  httpc_opts: [
    proxy: {{String.to_charlist(proxy_host), proxy_port}, []}
  ]
```    
## Backend selection

`TzWorld` provides alternative strategies for managing access to the backend data. Each backend is implemented as a `GenServer` that needs to be either manually started with `BackendModule.start_link/1` or preferably added to your application's supervision tree.

The recommended backend is `TzWorld.Backend.EtsWithIndexCache` unless the host system is memory constrained in which case `TzWorld.Backend.DetsWithIndexCache` is recommended.

For example:

```elixir
defmodule MyApp.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      ...
      TzWorld.Backend.EtsWithIndexCache
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```
The following backends are available:

* `TzWorld.Backend.Memory` which retains all data in memory for fast (but *not*
  fastest) performance at the expense of using approximately 1GB of memory

* `TzWorld.Backend.Dets` which uses Erlang's `:dets` data store. This uses
  negligible memory at the expense of slow access times (approximately 500ms in
  testing)

* `TzWorld.Backend.DetsWithIndexCache` which balances memory usage and
  performance. This backend is recommended in most situations since its
  performance is similar to `TzWorld.Backend.Memory` (about 5% slower in
  testing) and uses about 25Mb of memory

* `TzWorld.Backend.Ets` which uses `:ets` for storage. With the default
  settings of `:compressed` for the `:ets` table its memory consumption is
  about 512Mb  but with access that is over 20 times slower than
  `TzWorld.Backend.DetsWithIndexCache`

* `TzWorld.Backend.EtsWithIndexCache` which uses `:ets` for storage with an
  additional in-memory cache of the bounding boxes. This still uses about 512Mb
  but is faster than any of the other backends by about 40%
  
Other backends can be implemented as long as they follow the `TzWorld.Backend`
behaviour. Custom backends should be configured in `config.exs` or `runtime.exs`
under the `:backend` key so that it will be considered as the default for calls
to `TzWorld.timezone_at/1`. For example:

```elixir
config :tz_world,
  backend: MyTzWorldBackend
```

## Installing the Timezones Geo JSON data

Installing `tz_world` from source or from hex does not include the timezones
Geo JSON data. The data is required and to install or update it run:

```elixir
mix tz_world.update
```

This task will download, transform, zip and store the timezones Geo data. Depending on internet and computer speed this may take a few minutes.

By default `mix tz_world.update` will download geojson data that does *not* include time zone information for the oceans. There are two optional parameters that are accepted by `mix tz_world.update` that can be used to configure the desired behaviour:

* `--include-oceans` will download the geojson data, including data for the oceans. This give almost complete global coverage of time zone data.  The default is `--no-include-oceans` which does not include data that covers the oceans. The geojson data including the oceans is about 10% larger than the data that does not include the oceans.

* `--force` will force an update to the geojson data even if the installed data is the latest release. This option can be useful if you choose to switch from the data without ocean coverage to the data with ocean coverage (and the reverse). The default is `--no-force`.

### Updating the Timezone data

From time-to-time the timezones Geo JSON data is updated in the [upstream project](https://github.com/evansiroky/timezone-boundary-builder/releases). The mix task `mix tz_world.update` will update the data if it is available.

A running application can also be instructed to reload the data by executing `TzWorld.reload_timezone_data`.

## Usage

The primary API is `TzWorld.timezone_at`. It takes either a `Geo.Point` struct or a `longitude` and `latitude` in degrees. Note the parameter order: `longitude`, `latitude`. It also takes and optional second parameter, `backend`, which must be one of the configured and running backend modules.  By default `timezone_at/2` will detect a running backend and will raise an exception if no running backend is found.

```elixir
iex> TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
{:ok, "Europe/Paris"}

iex> TzWorld.timezone_at({3.2, 45.32})
{:ok, "Europe/Paris"}

iex> TzWorld.timezone_at(%Geo.PointZ{coordinates: {-74.006, 40.7128, 0.0}})
{:ok, "America/New_York"}

# Assumes that the downloaded data does not include
# data for the oceans (the default)
iex> TzWorld.timezone_at(%Geo.Point{coordinates: {1.3, 65.62}})
{:error, :time_zone_not_found}
```
