defmodule JasonVoegele.ShotSelectionStrategy.Random do
  def start_link do
    all_coordinates = for x <- 0..9, y <- 0..9, do: {x, y}
    Agent.start_link(fn -> all_coordinates end)
  end

  def select_shot(agent, _tracking_board, _remaining_ships) do
    remaining_coordinates = Agent.get(agent, &(&1))
    index = :rand.uniform(length(remaining_coordinates)) - 1
    shot = Enum.at(remaining_coordinates, index)
    Agent.update(agent, &(List.delete_at(&1, index)))
    shot
  end
end
