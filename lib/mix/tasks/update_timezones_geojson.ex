defmodule Mix.Tasks.TzWorld.Update do
  @moduledoc "Downloads and installs the latest Timezone GeoJSON data"

  @shortdoc "Downloads and installs the latest Timezone GeoJSON data"
  @tag "[TzWorld]"

  use Mix.Task
  alias TzWorld.Downloader
  require Logger

  def run(_args) do
    Application.ensure_all_started(:tz_world)

    case Downloader.current_release() do
      {:ok, current_release} ->
        {latest_release, asset_url} = Downloader.latest_release()
        if latest_release > current_release do
          Logger.info("#{@tag} Updating from release #{current_release} to #{latest_release}")
          Downloader.get_latest_release(latest_release, asset_url)
        else
          Logger.info("#{@tag} Currently installed release #{current_release} is the latest release")
        end

      {:error, :enoent} ->
        {latest_release, asset_url} = Downloader.latest_release()
        Logger.info("#{@tag} No timezone geo data installed. Installing the latest release #{latest_release}")
        Downloader.get_latest_release(latest_release, asset_url)

      other ->
        other
    end
  end
end
