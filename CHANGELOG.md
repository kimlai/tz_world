# Changelog for Tz_World v0.2.0

This is the changelog for Tz_World v0.2.0 released on ____.  For older changelogs please consult the release tag on [GitHub](https://github.com/kimlai/tz_world/tags)

### Breaking Changes

* `timezone_at/1` returns tagged tuples `{:ok, result}` or `{:error, reason}`. There can be at least two reasons for an error: no data file is available or no timezone is found. These return `{:error, :enoent}` and `{:error, :notfound}` respectively

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




