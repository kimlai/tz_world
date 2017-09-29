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
         {:ok, json} <- parse_json(data)
    do
      json
      |> decode()
      |> bulk_insert(repo)
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
    IO.puts "Reading geotada..."
    File.read(file)
  end

  defp parse_json(data) do
    IO.puts "Parsing json..."
    Poison.Parser.parse(data)
  end

  defp bulk_insert(entries, repo) do
    IO.puts "Populating the database..."
    repo_opts = [pool_timeout: :infinity]
    task_opts = [timeout: :infinity, max_concurrency: System.schedulers_online * 2, ordered: false]
    entries
    |> Enum.chunk_every(5)
    |> Task.async_stream(fn(chunk) -> repo.insert_all(TimezoneGeometry, chunk, repo_opts) end, task_opts)
    |> Stream.run()
  end

  defp decode(%{"features" => timezones}) do
    Enum.map(timezones, &decode(&1))
  end

  defp decode(%{"properties" => %{"tzid" => timezone}, "geometry" => geometry}) do
    %{timezone: timezone, geometry: Geo.JSON.decode(geometry)}
  end
end
