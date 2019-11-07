defmodule TzWorld.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      TzWorld
    ]

    opts = [strategy: :one_for_one, name: TzWorld.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
