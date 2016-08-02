# Usage:
#   mix run bin/play_game.exs Battleship.Player.Random Battleship.Player.Linear

[player1, player2] = Enum.map(System.argv, fn(arg) ->
  module = String.to_atom("Elixir." <> arg)
  {:ok, pid} = apply(module, :start_link, [])
  pid
end)

{:ok, game_pid} = Battleship.Game.Supervisor.start_game(player1, player2)
Battleship.Game.start_game(game_pid, {Battleship.TerminalRenderer, self})

receive do
  :game_over -> :ok
after
  120_000 -> IO.puts("Game aborted")
end
