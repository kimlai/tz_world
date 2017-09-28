defmodule Mix.Tasks.TzWorld.Install do
  @moduledoc """
  This task will boostrap the GeoJson dataset.

  - Fetch data from [there](https://github.com/evansiroky/timezone-boundary-builder/releases/2017a)
  - Unzip the archive
  - Parse the GeoJson data
  - Populate the database
  """

  @data_file "https://github.com/evansiroky/timezone-boundary-builder/releases/download/2017a/timezones.geojson.zip"
  @shortdoc "Populate the database with timezone data"

  use Mix.Task

  import Mix.Ecto

  alias TzWorld.TimezoneGeometry
  alias HTTPoison.Response

  @doc false
  def run(_) do
    repo = Application.get_env(:tz_world, :repo)
    ensure_repo(repo, [])
    ensure_started(repo, [])
    HTTPoison.start
    load_data(repo)
  end

  defp load_data(repo) do
    with archive <- download_archive(@data_file),
         {:ok, [file]} <- unzip(archive),
         {:ok, data} <- read(file),
         {:ok, json} <- Poison.decode(data)
    do
      json
      |> decode()
      |> log("Populating the database...")
      |> Enum.map(&repo.insert/1)
      File.rm_rf file
    end
  end

  defp download_archive(url) do
    IO.puts "Fetching geodata from #{url}"
    %Response{status_code: 200, body: body} = HTTPoison.get!(@data_file, [], follow_redirect: true)
    body
  end

  defp unzip(archive) do
    IO.puts "Unzipping archive..."
    :zip.unzip(archive)
    end

  defp read(file) do
    IO.puts "Parsing geotada..."
    File.read(file)
  end

  defp decode(%{"features" => timezones}) do
    Enum.map(timezones, &decode(&1))
  end

  defp decode(%{"properties" => %{"tzid" => timezone}, "geometry" => geometry}) do
    %TimezoneGeometry{timezone: timezone, geometry: Geo.JSON.decode(geometry)}
  end

  defp log(value, message) do
    IO.puts message
    value
  end
end
