defmodule TzWorld.Downloader do
  @moduledoc """
  Function to support downloading the latest
  timezones geo JSON data

  """

  alias TzWorld.GeoData
  require Logger

  @release_url "https://api.github.com/repos/evansiroky/timezone-boundary-builder/releases"
  @timezones_geojson "timezones.geojson.zip"

  @doc """
  Return the `{release_number, download_url}` of
  the latest timezones geo JSON data

  """
  def latest_release do
    with {:ok, releases} <- get_releases() do
      release = hd(releases)
      release_number = Map.get(release, "name")
      timezones_geojson_asset = find_asset(release, @timezones_geojson)
      asset_url = Map.get(timezones_geojson_asset, "browser_download_url")
      {release_number, asset_url}
    end
  end

  @doc """
  Returns the current installed timezones geo JSON
  data.

  """
  def current_release do
    GeoData.version()
  end

  @doc """
  Updates the timezone geo JSON data if there
  is a more recent release.

  """
  def update_release do
    case current_release() do
      {:ok, current_release} ->
        {latest_release, asset_url} = latest_release()
        if latest_release > current_release do
          get_and_load_latest_release(latest_release, asset_url)
        else
          {:ok, current_release}
        end

      {:error, :enoent} ->
        {latest_release, asset_url} = latest_release()
        get_and_load_latest_release(latest_release, asset_url)

      other ->
        other
    end
  end

  def get_and_load_latest_release(latest_release, asset_url) do
    with {:ok, _} <- get_latest_release(latest_release, asset_url) do
      TzWorld.reload_timezone_data()
    end
  end

  def get_latest_release(latest_release, asset_url) do
    with {:ok, source_data} <- get_url(asset_url) do
      GeoData.generate_compressed_data(source_data, latest_release)
    end
  end

  defp find_asset(release, requested_asset) do
    Map.get(release, "assets")
    |> Enum.find(fn asset -> Map.get(asset, "name") == requested_asset end)
  end

  defp get_releases do
    with {:ok, json} <- get_url(@release_url),
         {:ok, releases} <- Jason.decode(json) do
      {:ok, releases}
    end
  end

  defp get_url(url) when is_binary(url) do
    url
    |> to_charlist
    |> get_url
  end

  defp get_url(url) do
    require Logger

    case :httpc.request(:get, {url, headers()}, [], []) do
      {:ok, {{_version, 200, 'OK'}, _headers, body}} ->
        {:ok, :erlang.list_to_binary(body)}

      {_, {{_version, code, message}, _headers, body}} ->
        Logger.bare_log(
          :error,
          "Failed to download from #{inspect url}. HTTP Error: (#{code}) #{inspect(message)}. #{inspect body}"
        )

        {:error, code}

      {:error, {:failed_connect, [{_, {host, _port}}, {_, _, sys_message}]}} ->
        Logger.bare_log(
          :error,
          "Failed to connect to #{inspect(host)}. Reason: #{inspect(sys_message)}"
        )

        {:error, sys_message}
    end
  end

  defp headers do
    [
      {'User-Agent', 'httpc/22.0'}
    ]
  end
end