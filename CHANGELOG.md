## Changelog for Tz_World

## Tz_World v1.4.1

This is the changelog for Tz_World v1.4.1 released on ______, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Only include `:wx` and `:observer` in `:extra_applications` if they are configured in the runtime. Thanks to @mayel for the report. Fixes #43.

## Tz_World v1.4.0

This is the changelog for Tz_World v1.4.0 released on September 29th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Enhancements

* Adds support for easier configuration of default custom backends.  In previous releases, the default backend was resolved by only considering the built-in backends. From this release, a custom backend can be configured in `config.exs` or `runtime.exs`. If so configured, that backend will be the default for calls to `TzWorld.timezone_at/1`. For example:

```elixir
config :tz_world,
  default_backend: MyTzWorldBackend
```

* Adds a `--trace` flag to `mix tz_world.update`. This flag will trigger additional logging during the update process including memory utilization on the BEAM.

* Adds some memory use optimizations during the download process. Relates to #38 but likely does not fully solve this issue.
 
* Add support for [geo 4.0](https://github.com/felt/geo).

## Tz_World v1.3.3

This is the changelog for Tz_World v1.3.3 released on May 27th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Fixes compiler warnings for Elixir 1.17.

## Tz_World v1.3.2

This is the changelog for Tz_World v1.3.2 released on December 2nd 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Fixes compiler warnings for Elixir 1.16.

## Tz_World v1.3.1

This is the changelog for Tz_World v1.3.1 released on August 17th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

Thanks to @mjquinlan2000 for the report of issues on Elixir 1.15 and OTP 26.

* Always send a `User-Agent` header to the Github API to avoid 403 responses.

* Add `:ssl` to `:extra_applications` to support Elixir 1.15 and OTP 26.

* Update `TzWorld.Downloader.get_url/1` to follow the [erlef security guidelines](https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/ssl).

## Tz_World v1.3.0

This is the changelog for Tz_World v1.3.0 released on April 5th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Enhancements

* Add httpc [set_options/1](https://www.erlang.org/doc/man/httpc.html#set_options-1) support. Thanks to @gabrielgiordan for the PR (and the PR for fixing CI).

## Tz_World v1.2.0

This is the changelog for Tz_World v1.2.0 released on October 12th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Fix `TzWorld.Backend.Dets` to not raise an exception if there is no timezone data available.

### Enhancements

* Adds options to `mix tzworld.update` mix task:
  * `--include_oceans` will download a 10% larger geojson data set that covers the worlds oceans
  * `--force` will force a data update, even if the data is the latest release. This can be used
    to switch between data that includes oceans and that which does not.
  * Thanks to @lguminski for the feedback and suggestion.

## Tz_World v1.1.0

This is the changelog for Tz_World v1.1.0 released on August 26th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Enhancements

* Replace `Application.get_env/2` with `Application.compile_env/2` to remove warnings on Elixir 1.14. Now requires Elixir 1.10 as a minimum version.

## Tz_World v1.0.0

This is the changelog for Tz_World v1.0.0 released on October 19th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Enhancements

* Update to version 1.0.0 since the API has been stable for a year.

## Tz_World v0.7.1

This is the changelog for Tz_World v0.7.1 released on November 6th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Don't use tests for the external data version since that changes outside of the code lifesycle

## Tz_World v0.7.0

This is the changelog for Tz_World v0.7.0 released on October 10th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Add `:inets` and `:public_key` to `:extra_applications` in `mix.exs` to make Elixir 1.11 happy.

## Tz_World v0.6.0

This is the changelog for Tz_World v0.6.0 released on June 10th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Honour the configuration for `:data_dir`. Thanks to @superhawk610. Fixes #12

* Be more resilient if the `:dets` file is not in place

## Tz_World v0.5.0

This is the changelog for Tz_World v0.5.0 released on May 23rd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Bug Fixes

* Move compile time configuration of the data directory to runtime and remove hard-coded default path

* Start `:inets` and `:ssl` applications in the downloader mix task

* Add certificate verification when downloading updates to the geo data

### Enhancements

* Document the `:data_dir` and `:cacertfile` configuration options it the README.md file

* The backends `:dets` and `:dets_with_index_cache` now open the `:dets` file as `access: :read` which prevents errors if the file is abnormally closed.

## Tz_World v0.4.0

This is the changelog for Tz_World v0.4.0 released on May 12th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

* Adds configurable backends. Each backend is a GenServer that must be added to an applications supervision tree or started manually.

### Breaking change

* When specifying a `lng`, `lat` to `TzWorld.timezone_at/2` the coordinates must be wrapped in a tuple. For example `TzWorld.timezone_at({3.2, 45.32})` making it consistent with the `Geo.Point` and `Geo.PointZ` strategies.

### Configurable backends

* `TzWorld.Backend.Memory` which retains all data in memory for fast (but *not* fastest) performance at the expense of using approximately 1Gb of memory
* `TzWorld.Backend.Dets` which uses Erlang's `:dets` data store. This uses negligible memory at the expense of slow access times (approximaltey 500ms in testing)
* `TzWorld.Backend.DetsWithIndexCache` which balances memory usage and performance. This backend is recommended in most situations since its performance is similar to `TzWorld.Backend.Memory` (about 5% slower in testing) and uses about 25Mb of memory
* `TzWorld.Backend.Ets` which uses `:ets` for storage. With the default settings of `:compressed` for the `:ets` table its memory consumption is about 512Mb but with access that is over 20 times slower than `TzWorld.Backend.DetsWithIndexCache`
* `TzWorld.Backend.EtsWithIndexCache` which uses `:ets` for storage with an additional in-memory cache of the bounding boxes. This still uses about 512Mb but is faster than any of the other backends by about 40%

### Enhancements

* Add `TzWorld.all_timezones_at/2` to return all timezones for a given location.  In rare cases, usually disputed territory, multiple timezones may be declared for overlapping regions. `TzWorld.all_timezones_at/2` returns a (potentially empty) list of all time zones known for a given point.  *Futher testing of this function is required and will be completed before version 1.0*.

## Tz_World v0.3.0

This is the changelog for Tz_World v0.3.0 released on December 4th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Breaking Changes

* Changes the error return from `{:error, :timezone_not_found}` to `{:error, :time_zone_not_found}` since both Elixir and Tzdata use `time_zone`.

### Enhancements

* Allows both `%Geo.Point{}` and `%Geo.PointZ{}` as parameters to `TzWorld.timezone_at/1`

## Tz_World v0.2.0

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




