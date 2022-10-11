defmodule TzWorld.Downloader do
  @moduledoc """
  Function to support downloading the latest
  timezones geo JSON data

  """

  alias TzWorld.GeoData
  require Logger

  @release_url "https://api.github.com/repos/evansiroky/timezone-boundary-builder/releases"
  @timezones_geojson "timezones.geojson.zip"
  @timezones_with_oceans_geojson "timezones-with-oceans.geojson.zip"

  @doc """
  Return the `{release_number, download_url}` of
  the latest timezones geo JSON data

  """
  def latest_release(include_oceans? \\ false) do
    with {:ok, releases} <- get_releases() do
      release = hd(releases)
      release_number = Map.get(release, "name")
      asset_name = asset_name(include_oceans?)
      timezones_geojson_asset = find_asset(release, asset_name)
      asset_url = Map.get(timezones_geojson_asset, "browser_download_url")
      {release_number, asset_url}
    end
  end

  defp asset_name(true), do: @timezones_with_oceans_geojson
  defp asset_name(false), do: @timezones_geojson

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
      TzWorld.Backend.Dets.start_link()
      TzWorld.Backend.Dets.reload_timezone_data()
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

    case  :httpc.request(:get, {url, headers()}, https_opts(), []) do
      {:ok, {{_version, 200, 'OK'}, _headers, body}} ->
        {:ok, :erlang.list_to_binary(body)}

      {_, {{_version, code, message}, _headers, body}} ->
        Logger.bare_log(
          :error,
          "Failed to download from #{inspect(url)}. HTTP Error: (#{code}) #{inspect(message)}. #{
            inspect(body)
          }"
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

  @certificate_locations [
      # Configured cacertfile
      Application.compile_env(:tz_world, :cacertfile),

      # Populated if hex package CAStore is configured
      if(Code.ensure_loaded?(CAStore), do: CAStore.file_path()),

      # Populated if hex package certfi is configured
      if(Code.ensure_loaded?(:certifi), do: :certifi.cacertfile() |> List.to_string),

      # Debian/Ubuntu/Gentoo etc.
      "/etc/ssl/certs/ca-certificates.crt",

      # Fedora/RHEL 6
      "/etc/pki/tls/certs/ca-bundle.crt",

      # OpenSUSE
      "/etc/ssl/ca-bundle.pem",

      # OpenELEC
      "/etc/pki/tls/cacert.pem",

      # CentOS/RHEL 7
      "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",

      # Open SSL on MacOS
      "/usr/local/etc/openssl/cert.pem",

      # MacOS & Alpine Linux
      "/etc/ssl/cert.pem"
  ]
  |> Enum.reject(&is_nil/1)

  def certificate_store do
    @certificate_locations
    |> Enum.find(&File.exists?/1)
    |> raise_if_no_cacertfile
    |> :erlang.binary_to_list
  end

  defp raise_if_no_cacertfile(nil) do
    raise RuntimeError, """
      No certificate trust store was found.
      Tried looking for: #{inspect @certificate_locations}

      A certificate trust store is required in
      order to download locales for your configuration.

      Since ex_cldr could not detect a system
      installed certificate trust store one of the
      following actions may be taken:

      1. Install the hex package `castore`. It will
         be automatically detected after recompilation.

      2. Install the hex package `certifi`. It will
         be automatically detected after recomilation.

      3. Specify the location of a certificate trust store
         by configuring it in `config.exs`:

         config :ex_cldr,
           cacertfile: "/path/to/cacertfile",
           ...

      """
  end

  defp raise_if_no_cacertfile(file) do
    file
  end

  defp https_opts do
    [ssl:
      [
        verify: :verify_peer,
        cacertfile: certificate_store(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]
  end

end
