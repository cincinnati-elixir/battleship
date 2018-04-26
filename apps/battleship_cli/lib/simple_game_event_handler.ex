defmodule Battleship.SimpleGameEventHandler do
  use GenEvent

  ## GenEvent callbacks

  def handle_event({:new_game, game_state}, state) do
    [player1, player2] = game_state
    print("New game between #{player1.name} and #{player2.name}")
    {:ok, state}
  end

  def handle_event({:game_over, :illegal_game}, state) do
    print("GAME ERROR - both players disqualified")
    {:ok, state}
  end

  def handle_event({:game_over, %{winner: player}}, state) do
    print("GAME OVER - #{player.name} wins!")
    {:ok, state}
  end

  def handle_event({:move, {move_info, game_state}}, state) do
    [player1, player2] = game_state
    print("#{move_info.by} fires at #{inspect move_info.target}: #{inspect move_info.result}")
    print("#{player1.name} remaining ships:\n\t#{inspect player1.remaining_ships}")
    print("#{player2.name} remaining ships:\n\t#{inspect player2.remaining_ships}\n")
    {:ok, state}
  end

  def handle_event({:illegal_move, move_info}, state) do
    print("ILLEGAL MOVE by #{move_info.by}: #{inspect move_info.target}")
    {:ok, state}
  end

  defp print(message) do
    IO.puts(Process.group_leader, message)
  end
end
