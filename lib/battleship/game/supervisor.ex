defmodule Battleship.Game.Supervisor do
  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_game(player1, player2) when is_pid(player1) and is_pid(player2) do
    Supervisor.start_child(@name, [[player1, player2]])
  end

  def start_game(player1_module, player2_module) do
    start_game(start_player(player1_module), start_player(player2_module))
  end

  def init(:ok) do
    children = [
      worker(Battleship.Game, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp start_player(player_module) when is_atom(player_module) do
    # {:ok, pid} = GenServer.start(player_module, [])
    {:ok, player_sup} = Battleship.Player.Supervisor.start_link(player_module)
    {:ok, pid} = Supervisor.start_child(player_sup, [])
    pid
  end
  defp start_player(player_file) when is_binary(player_file) do
    [{player_module, _code}] = Code.load_file(player_file)
    start_player(player_module)
  end
end
