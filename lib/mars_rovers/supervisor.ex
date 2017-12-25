defmodule MarsRovers.Supervisor do
  use Supervisor

  def start_link(objectives) do
    Supervisor.start_link(__MODULE__, objectives, name: __MODULE__)
  end

  def init(objectives) do
    children = [
      worker(MarsRovers.SpaceShip, [objectives])
    ]

    opts = [strategy: :one_for_all]

    supervise(children, opts)
  end
end
