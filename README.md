# TzWorld

Resolve timezones from a location efficiently using PostGIS and Ecto ([documentation](https://hexdocs.pm/tz_world)).

`TzWorld` works by fetching timezone GeoJson data from [this project](https://github.com/evansiroky/timezone-boundary-builder), and then inserting it in a PostGIS table. Once populated, the database can be queried to retrieve a timezone name from coordinates.

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

2. Set your Ecto repository in your `config.ex`:
```elixir
config :tz_world,
  repo: MyApp.Repo
```

3. If you haven't already done so, add the `Geo.PostGIS` Ecto [extension](https://hexdocs.pm/ecto/Ecto.Adapters.Postgres.html#module-extensions) to your project
```elixir
# Create a new file anywhere in your application with the following:
Postgrex.Types.define(MyApp.PostgresTypes,
                      [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
                      json: Poison)

```

4. Generate the migration to create the PostGIS table that will hold the GeoJson data:
```
$ mix tz_world.gen.migration
```
Then run the migration with `mix ecto.migrate`.

5. Populate the table:
```
$ mix tz_world.install
```
This will Fetch GeoJson data from [here](https://github.com/evansiroky/timezone-boundary-builder/releases/tag/2017a), and insert it your database.

## Usage

```elixir
TzWorld.timezone_at(%Geo.Point{coordinates: {3.2, 45.32}})
"Europe/Paris"
```
