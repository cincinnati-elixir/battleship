defmodule Battleship.Player.Random do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_arg) do
    # Use a list of all possible valid coordinates as our state. We will then
    # take one coordinate from the list randomly on each turn.
    all_coordinates = for x <- 0..9, y <- 0..9, do: {x, y}
    {:ok, all_coordinates}
  end

  def handle_call(:name, _from, state) do
    {:reply, "Random", state}
  end

  def handle_call(:new_game, _from, state) do
    :random.seed(:erlang.now)
    fleet = [
      {1, 1, 5, :down},
      {6, 8, 4, :across},
      {3, 2, 3, :down},
      {7, 2, 3, :across},
      {2, 7, 2, :across}
    ]
    {:reply, fleet, state}
  end

  def handle_call({:take_turn, _tracking_board, _remaining_ships}, _from,
                  remaining_coordinates) do
    index = :random.uniform(Enum.count(remaining_coordinates)) - 1
    shot = Enum.at(remaining_coordinates, index)
    {:reply, shot, List.delete_at(remaining_coordinates, index)}
  end
end
