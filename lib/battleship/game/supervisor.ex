defmodule Battleship.Game.Supervisor do
  use Supervisor

  @name __MODULE__

  def start_link do
    IO.puts("Starting game supervisor...")
    result = Supervisor.start_link(__MODULE__, :ok, name: @name)
    IO.puts("done")
    result
  end

  def start_game(player1, player2) when is_pid(player1)
  and is_pid(player2) do
    Supervisor.start_child(@name, [[player1, player2]])
  end

  def start_game(player1_module, player2_module)
  when is_atom(player1_module) and is_atom(player2_module) do
    start_game(start_player(player1_module), start_player(player2_module))
  end

  def init(:ok) do
    children = [
      worker(Battleship.Game, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp start_player(player_module) do
    {:ok, pid} = apply(player_module, :start_link, [])
    pid
  end
end
