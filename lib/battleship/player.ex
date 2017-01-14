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

  def start_link(player_module, reg_name) do
    GenServer.start_link(player_module, [], name: via(reg_name))
  end

  def via(reg_name) do
    via = {:via, Registry, {Battleship.Player.Registry, reg_name}}
  end

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
      result = GenServer.call(via(player), message, 2000)
      {:ok, result}
    catch
      :exit, reason ->
        {:error, reason}
      error ->
        {:error, error}
    end
  end
end
