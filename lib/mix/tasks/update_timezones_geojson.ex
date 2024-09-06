defmodule Mix.Tasks.TzWorld.Update do
  @moduledoc """
  Downloads and installs the latest Timezone GeoJSON data.

  ## Argument

  * `--include-oceans` Will include the geojson for
    oceans in the downloaded data.

  * `--force` will force an update even if the data is
    current. This can be used to force downloading data
    including (or not including) time zone data for the oceans.

  """

  @shortdoc "Downloads and installs the latest Timezone GeoJSON data"
  @tag "[TzWorld]"

  @aliases [o: :include_oceans, f: :force, t: :trace]
  @strict [include_oceans: :boolean, force: :boolean, trace: :boolean]

  use Mix.Task
  alias TzWorld.Downloader
  require Logger

  def run(args) do
    case OptionParser.parse(args, aliases: @aliases, strict: @strict) do
      {options, [], []} ->
        include_oceans? = Keyword.get(options, :include_oceans, false)
        force_update? = Keyword.get(options, :force, false)
        trace? = Keyword.get(options, :trace, false)

        update(include_oceans?, force_update?, trace?)

      _other ->
        Mix.raise(
        """
        Invalid arguments found. `mix tz_world.update` accepts the following:
          --include-oceans
          --no-include-oceans (default)
          --force
          --no-force (default)
          --trace
          --no-trace (default)
        """,
        exit_status: 1)
    end
  end

  def update(include_oceans?, true = _force_update?, trace?) do
    start_applications()

    {latest_release, asset_url} = Downloader.latest_release(include_oceans?, trace?)
    Downloader.get_latest_release(latest_release, asset_url, trace?)

    :ok = TzWorld.Backend.Memory.stop()
    :ok = TzWorld.Backend.Dets.stop()
    :erlang.garbage_collect()
  end

  def update(include_oceans?, false = _force_update?) do
    start_applications()

    case Downloader.current_release() do
      {:ok, current_release} ->
        {latest_release, asset_url} = Downloader.latest_release(include_oceans?)

        if latest_release > current_release do
          Logger.info("#{@tag} Updating from release #{current_release} to #{latest_release}.")
          Downloader.get_latest_release(latest_release, asset_url)
        else
          Logger.info(
            "#{@tag} Currently installed release #{current_release} is the latest release."
          )
        end

      {:error, :enoent} ->
        {latest_release, asset_url} = Downloader.latest_release(include_oceans?)

        Logger.info(
          "#{@tag} No timezone geo data installed. Installing the latest release #{latest_release}."
        )

        Downloader.get_latest_release(latest_release, asset_url)
    end
  end

  defp start_applications do
    {:ok, _} = Application.ensure_all_started(:tz_world)
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:module, _} = Code.ensure_loaded(:ssl_cipher)

    TzWorld.Backend.Memory.start_link()
    TzWorld.Backend.Dets.start_link()
  end
end
