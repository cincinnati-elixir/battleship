defmodule JasonVoegele do
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
    {:reply, "Jason Voegele", state}
  end

  def handle_call(:new_game, _from, state) do
    :random.seed(:erlang.now)
    fleet = [
      {5, 9, 5, :across},
      {6, 8, 4, :across},
      {7, 7, 3, :across},
      {7, 6, 3, :across},
      {8, 5, 2, :across}
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
