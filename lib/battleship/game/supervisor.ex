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

  def start_tournament(player1_module, player2_module) do
    p1 = start_player(player1_module)
    p2 = start_player(player2_module)
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
  defp start_player(player) when is_binary(player) do
    player_module = if String.ends_with?(player, ".exs") do
      [{player_module, _code}] = Code.load_file(player)
      player_module
    else
      String.to_atom("Elixir." <> player)
    end
    start_player(player_module)
  end
end
