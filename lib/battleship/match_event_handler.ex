defmodule Battleship.MatchEventHandler do
  use GenEvent

  def init(match_over_listener) do
    state = %{
      match_over_listener: match_over_listener,
      games_completed: 0,
      game_results: []
    }
    {:ok, state}
  end

  def handle_event({:start_match, players, num_games}, state) do
    [{p1_id, p1_name}, {p2_id, p2_name}] = players
    new_state = Map.merge(state, %{
      player1_id: p1_id,
      player1_name: p1_name,
      player2_id: p2_id,
      player2_name: p2_name,
      num_games: num_games})
    print("Starting #{num_games} game match between #{p1_name} and #{p2_name}")
    {:ok, new_state}
  end

  def handle_event({:new_game, game_state}, state) do
    game_number = state.games_completed + 1
    print("Starting game ##{game_number}")
    {:ok, state}
  end

  def handle_event({:move, {move_info, game_state}}, state) do
    {:ok, state}
  end

  def handle_event({:illegal_move, move_info}, state) do
    print("ILLEGAL MOVE by #{move_info.by}: #{inspect move_info.target}")
    {:ok, state}
  end

  def handle_event({:game_over, :illegal_game}, state) do
    print("GAME ERROR - both players disqualified")
    {:ok, Map.update!(state, :games_completed, &(&1 + 1))}
  end

  def handle_event({:game_over, %{winner: player}}, state) do
    shot_count = length(player.shots)
    print("GAME OVER - #{player.name} wins! (#{shot_count} moves)")
    new_state =
      state
      |> Map.update!(:games_completed, &(&1 + 1))
      |> Map.update!(:game_results, &([{player.pid, shot_count}|&1]))
    {:ok, new_state}
  end

  def handle_event(:match_over, state) do
    print("Match over!")
    split_victories = Enum.split_with(state.game_results,
                                      fn({winner, _}) ->
                                        winner == state.player1_id
                                      end)
    {p1_victories, p2_victories} = split_victories
    print_summary(state.player1_name, p1_victories)
    print_summary(state.player2_name, p2_victories)
    send(state.match_over_listener, :match_over)
    {:ok, state}
  end

  defp print(message) do
    IO.puts(Process.group_leader, message)
  end

  defp print_summary(player, victories) do
    num_victories = Enum.count(victories)
    total_moves =
      victories
      |> Enum.map(fn({_, moves}) -> moves end)
      |> Enum.sum
    case num_victories do
      0 ->
        print("#{player} did not win any games.")
      _ ->
        avg_moves = total_moves / num_victories
        print("#{player} won #{num_victories} games with an average of #{avg_moves} moves.")
    end
  end
end
