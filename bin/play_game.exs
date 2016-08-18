# Usage:
#   mix run bin/play_game.exs players/example/linear.exs players/example/random.exs

[player1, player2] = System.argv
{:ok, game_pid} = Battleship.Game.Supervisor.start_game(player1, player2)
Battleship.Game.start_game(game_pid, {Battleship.TerminalRenderer, self})
:observer.start

receive do
  :game_over -> :ok
after
  60_000 -> IO.puts("Game aborted")
end

