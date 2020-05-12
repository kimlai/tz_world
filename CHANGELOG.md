# Changelog for Tz_World v0.4.0

This is the changelog for Tz_World v0.4.0 released on May 12th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

* Adds configurable backends. Each backend is a GenServer that must be added to an applications supervision tree or started manually.

### Breaking change

* When specifying a `lng`, `lat` to `TzWorld.timezone_at/2` the coordinates must be wrapped in a tuple. For example `TzWorld.timezone_at({3.2, 45.32})` making it consistent with the `Geo.Point` and `Geo.PointZ` strategies.

### Configurable backends

* `TzWorld.Backend.Memory` which retains all data in memory for fastest performance at the expense of using approximately 1Gb of memory
* `TzWorld.Backend.Dets` which uses Erlang's `:dets` data store. This uses negligible memory at the expense of slow access times (approximaltey 500ms in testing)
* `TzWorld.Backend.DetsWithIndexCache` which balances memory usage and performance. This backend is recommended in most situations since its performance is similar to `TzWorld.Backend.Memory` (about 5% slower in testing) and uses about 25Mb of memory
* `TzWorld.Backend.Ets` which uses `:ets` for storage. With the default settings of `:compressed` for the `:ets` table its memory consumption is about 512Mb but with access that is over 20 times slower than `TzWorld.Backend.DetsWithIndexCache`
* `TzWorld.Backend.EtsWithIndexCache` which uses `:ets` for storage with an additional in-memory cache of the bounding boxes. This still uses about 512Mb but is faster than any of the other backends by about 40%

### Enhancements

* Add `TzWorld.all_timezones_at/2` to return all timezones for a given location.  In rare cases, usually disputed territory, multiple timezones may be declared for a overlapping regions. `TzWorld.all_timezones_at/2` returns a (potentially empty) list of all time zones knowns for a given point.  *Futher testing of this function is required and will be completed before version 1.0*.

# Changelog for Tz_World v0.3.0

This is the changelog for Tz_World v0.3.0 released on December 4th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Breaking Changes

* Changes the error return from `{:error, :timezone_not_found}` to `{:error, :time_zone_not_found}` since both Elixir and Tzdata use `time_zone`.

### Enhancements

* Allows both `%Geo.Point{}` and `%Geo.PointZ{}` as parameters to `TzWorld.timezone_at/1`

# Changelog for Tz_World v0.2.0

This is the changelog for Tz_World v0.2.0 released on November 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Breaking Changes

* Requires OTP 21 and Elixir 1.6 or later due to the use of GenServer's `handle_continue/2`

* `timezone_at/1` returns tagged tuples `{:ok, result}` or `{:error, reason}`. There can be at least two reasons for an error: no data file is available or no timezone is found. These return `{:error, :enoent}` and `{:error, :timezone_not_found}` respectively

* The timezone geojson data is no longer included in the package. Run `mix tz_world.update` to install or update it.

* No longer uses Ecto or PostGIS for calculations.

### Enhancements

* Updated to latest shape data. Takes the geo JSON shape data directly from [timezone-boundary-builder releases](https://github.com/evansiroky/timezone-boundary-builder/releases)

* Conforms TzWorker to the modern `child_spec/1` including using `handle_continue/2` to load the data file if it exists.

* Updated dependencies including [geo](https://hex.pm/packages/geo) to allow `1.x`, `2.x` or `3.x`

* Added `Jason` as an optional dependency to facilitate decoding the GeoJSON from `timezone_boundary_builder`

* The timezone geojson data is no longer included in the package. Its size isn't supported on hex and it bloats the repo too. A mix task `tz_world.update` downloads and processes the data. The function `TzWorld.Downloader.update_release/0` can be called at any time to look for a new release, download it and load it into the running server with no downtime.

* `timezone_at/1` supports simple `lng`, `lat` arguments as well as `%Geo.Point{}` structs

* Added `CHANGELOG.md`

* Added SRID to the GeoJSON

* Updated package and ran dialyzer

* Added a config option :data_dir specifies the location of the compressed etf. Default is `./priv`

* Updated README, package and docs




