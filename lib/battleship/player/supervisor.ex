defmodule Battleship.Player.Supervisor do
  use Supervisor

  @name __MODULE__

  def start_link(player_module) do
    Supervisor.start_link(__MODULE__, player_module)
  end

  def init(player_module) do
    children = [worker(player_module, [], restart: :temporary)]
    supervise(children, strategy: :simple_one_for_one)
  end
end
