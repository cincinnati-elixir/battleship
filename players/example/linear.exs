defmodule Battleship.Player.Linear do
  use GenServer

  def init(_arg) do
    state = %{grid: Grid.new(10), last_shot: -1}
    {:ok, state}
  end

  def handle_call(:name, _from, state) do
    {:reply, "Linear", state}
  end

  def handle_call(:new_game, _from, state) do
    fleet = [
      {0, 0, 5, :across},
      {0, 1, 4, :across},
      {0, 2, 3, :across},
      {0, 3, 3, :across},
      {0, 4, 2, :across}
    ]

    {:reply, fleet, state}
  end

  def handle_call({:take_turn, _tracking_board, _remaining_ships}, _from, state) do
    shot_index = state.last_shot + 1
    if shot_index >= 11, do: exit(:boom)
    shot_coordinate = Grid.index_to_coordinate(state.grid, shot_index)
    new_state = %{state | last_shot: shot_index}

    {:reply, shot_coordinate, new_state}
  end
end

