defmodule Battleship.Player do
  # @moduledoc """
  # Defines the behaviour required for Battleship Player implementations.
  # """
  #
  # @doc "Start the player process and return its pid"
  # @callback start_link() :: pid
  #
  # @doc "The name of this player."
  # @callback name(pid) :: String.t
  #
  # @callback new_game(pid) :: [Battleship.Game.ship, ...]
  #
  # @callback take_turn(pid, Battleship.Game.state, [Battleship.Game.ship]) ::
  #   Battleship.Board.coordinate

  def start_link(player_module, player_id) do
    GenServer.start_link(player_module, [], name: registered_name(player_id))
  end

  def monitor(player_id) do
    case :global.whereis_name(player_id) do
      :undefined ->
        nil
      pid ->
        Process.monitor(pid)
    end
  end

  def registered_name(player_id) do
    {:global, player_id}
  end

  def name(player_id) do
    call_player(player_id, :name)
  end

  def new_game(player_id) do
    call_player(player_id, :new_game)
  end

  def take_turn(player_id, board_status, remaining_ships) do
    call_player(player_id, {:take_turn, board_status, remaining_ships})
  end

  defp call_player(player_id, message) do
    try do
      result = GenServer.call(registered_name(player_id), message, 2000)
      {:ok, result}
    catch
      :exit, reason ->
        {:error, reason}
      error ->
        {:error, error}
    end
  end
end
