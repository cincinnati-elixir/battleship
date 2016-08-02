defmodule Battleship.PlayerProxy do
  def name(player) do
    call_player(player, :name)
  end

  def new_game(player) do
    call_player(player, :new_game)
  end

  def take_turn(player, board_status, remaining_ships) do
    call_player(player, {:take_turn, board_status, remaining_ships})
  end

  defp call_player(player, message) do
    try do
      result = GenServer.call(player, message, 2000)
      {:ok, result}
    rescue
      error ->
        {:error, error}
    end
  end
end
