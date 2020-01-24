<<<<<<< HEAD
# Changelog for Tz_World v0.2.0

This is the changelog for Tz_World v0.2.0 released on ____.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)
=======
# Changelog for Tz_World v0.3.0

This is the changelog for Tz_World v0.3.0 released on December 4th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Breaking Changes

* Changes the error return from `{:error, :timezone_not_found}` to `{:error, :time_zone_not_found}` since both Elixir and Tzdata use `time_zone`.

### Enhancements

* Allows both `%Geo.Point{}` and `%Geo.PointZ{}` as parameters to `TzWorld.timezone_at/1`

# Changelog for Tz_World v0.2.0

This is the changelog for Tz_World v0.2.0 released on November 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)
>>>>>>> 25805788bb8cd9a5f08fbc050ab7e4363310f2e0

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

<<<<<<< HEAD
* Updated package and ran dialyzer

=======
>>>>>>> 25805788bb8cd9a5f08fbc050ab7e4363310f2e0
* Added a config option :data_dir specifies the location of the compressed etf. Default is `./priv`

* Updated README, package and docs




