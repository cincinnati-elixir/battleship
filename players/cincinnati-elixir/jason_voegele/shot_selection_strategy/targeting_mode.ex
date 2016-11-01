defmodule JasonVoegele.ShotSelectionStrategy.TargetingMode do
  import JasonVoegele.ShotSelectionStrategy

  defp make_move(%{mode: :targeting, last_shot_result: :hit} = state, board) do
    hit_stack = [state.last_shot | state.hit_stack]
    candidates =
      possible_ship_coordinates(board, state.last_shot) ++ state.candidates
    {shot, new_candidates} = select_candidate(board, candidates, hit_stack)

    take_shot(%{state | hit_stack: hit_stack}, shot, new_candidates)
  end

  defp make_move(%{mode: :targeting, last_shot_result: :miss} = state, board) do
    {shot, new_candidates} =
      select_candidate(board, state.candidates, state.hit_stack)
    take_shot(%{state | hit_stack: state.hit_stack}, shot, new_candidates)
  end

  def targeting_direction([]), do: nil
  def targeting_direction([_]), do: nil
  def targeting_direction(hit_stack) do
    [x_count, y_count] =
      hit_stack
      |> Enum.unzip
      |> Tuple.to_list
      |> Enum.map(&Enum.uniq(&1))
      |> Enum.map(&Enum.count(&1))
    cond do
      x_count > y_count -> :horizontal
      x_count < y_count -> :vertical
      true -> nil
    end
  end

  def matches_targeting?(direction, :vertical) do
    direction in [:up, :down, :north, :south]
  end
  def matches_targeting?(direction, :horizontal) do
    direction in [:left, :right, :west, :east]
  end
  def matches_targeting?(_, nil), do: true
end
