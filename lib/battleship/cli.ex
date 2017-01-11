defmodule Battleship.CLI do
  def main(args) do
    {options, argv, errors} = parse_args(args)
    handle_errors!(errors, argv, options)
    execute(argv, options)
  end

  defp parse_args(args) do
    OptionParser.parse(args)
  end

  defp handle_errors!([], _, _), do: :nothing
  defp handle_errors!(errors, _argv, _options) do
    raise "Invalid command-line arguments: #{IO.inspect errors}"
  end

  defp execute(["start-player" | args], options) do
    start_player(args)
  end
  defp execute(["start-game" | args], options) do
    start_game(args)
  end
  defp execute(["start-tournament" | args], options) do
    start_tournament(args)
  end
  defp execute(_args, _options) do
    IO.puts(:stderr, usage())
  end

  defp usage do
    "Usage: ..."
  end

  defp start_game([player1, player2]) do
    IO.puts("Starting game with #{IO.inspect player1} and #{IO.inspect player2}")
    {:ok, game_pid} = Battleship.Game.Supervisor.start_game(player1, player2)
    Battleship.Game.start_game(game_pid, {Battleship.TerminalRenderer, self})
    wait_for_game_over()
  end
  defp start_game(_invalid_args) do
    IO.puts(:stderr, "Usage: battleship start-game <Player1 Module> <Player2 Module>")
  end

  defp start_tournament([player1, player2]) do
    IO.puts("Starting tournament with #{IO.inspect player1} and #{IO.inspect player2}")
    Battleship.Game.Supervisor.start_tournament(player1, player2)
  end
  defp start_tournament(_invalid_args) do
    IO.puts(:stderr, "Usage: battleship start-tournament <Player1 Module> <Player2 Module>")
  end

  defp start_player([player_module_arg]) do
    IO.puts("Starting player #{IO.inspect player_module_arg}")
    player_module_name = "Elixir." <> player_module_arg
    player_module = String.to_atom(player_module_name)
    player_init = apply(player_module, :init, [:hello])
    IO.inspect(player_init)
  end
  defp start_player(_invalid_args) do
    IO.puts(:stderr, "Usage: battleship start-player <Player Module>")
  end

  defp wait_for_game_over(timeout \\ 60_000) do
    receive do
      :game_over -> :ok
    after
      timeout -> IO.puts("Game aborted")
    end
  end
end
