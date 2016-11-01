defmodule JasonVoegele.Player do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @shot_selection_strategy JasonVoegele.ShotSelectionStrategy.HuntAndTarget

  defstruct shots: [],
            remaining_ships: [5, 4, 3, 3, 2],
            select_shot: nil

  def init(_) do
    state = %__MODULE__{}
    {:ok, state}
  end

  def handle_call(:name, _from, state) do
    {:reply, "Jason Voegele", state}
  end

  def handle_call(:new_game, _from, _state) do
    fleet = [
      {5, 9, 5, :across},
      {6, 8, 4, :across},
      {7, 7, 3, :across},
      {7, 6, 3, :across},
      {8, 5, 2, :across}
    ]
    state = %__MODULE__{
      select_shot: create_select_shot_fn
    }
    {:reply, fleet, state}
  end

  def handle_call({:take_turn, tracking_board, remaining_ships}, _from, state) do
    {:ok, board} = Grid.from_list(tracking_board)
    shot = state.select_shot.(board, remaining_ships)

    new_state =
      %{state | remaining_ships: remaining_ships}
      |> Map.update!(:shots, &([shot|&1]))
    {:reply, shot, new_state}
  end

  # Create a function that captures the pid of the strategy agent so that it
  # can be called without the agent pid, as this is an implementation detail
  # that should not be exposed to callers.
  defp create_select_shot_fn do
    {:ok, agent} = @shot_selection_strategy.start_link
    fn(tracking_board, remaining_ships) ->
      @shot_selection_strategy.select_shot(agent,
                                           tracking_board,
                                           remaining_ships)
    end
  end
end
