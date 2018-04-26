defmodule JasonVoegele.ShotSelectionStrategy.HuntAndTarget do
  import JasonVoegele.ShotSelectionStrategy

  defstruct shots: [],
            last_shot: nil,
            last_shot_result: nil,
            remaining_ships: [5, 4, 3, 3, 2],
            remaining_coordinates: all_coordinates,
            mode: :hunting,
            candidates: [],
            hit_stack: []

  def start_link do
    Agent.start_link(fn -> %__MODULE__{} end)
  end

  def select_shot(agent, tracking_board, remaining_ships) do
    state = update_state_for_last_turn(Agent.get(agent, &(&1)),
                                       tracking_board,
                                       remaining_ships)
    new_state = make_move(state, tracking_board)
    Agent.update(agent, fn(_) -> new_state end)
    new_state.last_shot
  end

  defp update_state_for_last_turn(state, tracking_board, remaining_ships) do
    last_shot_result =
      shot_result(tracking_board,
                  state.last_shot,
                  remaining_ships,
                  state.remaining_ships)

    %{state |
      last_shot_result: last_shot_result,
      remaining_ships: remaining_ships,
      mode: select_mode(state.mode, last_shot_result)
    }
  end

  defp make_move(%{mode: :hunting} = state, board) do
    coordinates = state.remaining_coordinates
    # shot = select_random_with_parity(coordinates, Enum.min(state.remaining_ships))
    shot = select_by_probability(board, state.remaining_ships)
    take_shot(%{state | hit_stack: []}, shot, [])
  end

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

  defp make_move(state, board) do
    exit(state)
  end

  defp select_by_probability(tracking_board, remaining_ships) do
    probability_grid =
      create_probability_grid(tracking_board, remaining_ships)
    probability_vector =
      Grid.with_coordinate(probability_grid)
      |> Enum.reduce([], fn({p, coord}, acc) ->
        acc ++ List.duplicate(coord, p)
      end)
      |> filter_by_parity(Enum.min(remaining_ships))
# max_p = {_, coord} = Enum.max_by(Grid.with_coordinate(probability_grid), fn({val, _}) -> val end)
# parity = coord in probability_vector
# IO.puts("Max probability: #{inspect max_p}, parity? #{inspect parity}")
    index = :rand.uniform(length(probability_vector)) - 1
    Enum.at(probability_vector, index)
  end

  defp filter_by_parity(coordinates, parity) do
    parity_grid =
      Grid.new(10)
      |> Grid.map(fn(_, {x, y}) -> rem(x + y, parity) end)
    Enum.filter(coordinates, fn(coord) ->
      Grid.fetch!(parity_grid, coord) == 0
    end)
  end

  defp select_random_with_parity(coordinates, parity) do
    candidates =
      case filter_by_parity(coordinates, parity) do
        [] -> coordinates
        parity_matched -> parity_matched
      end
    index = :rand.uniform(length(candidates)) - 1
    Enum.at(candidates, index)
  end

  defp select_candidate(_board, candidates, hit_stack) do
    sorted_candidates = sort_candidates(candidates, hit_stack)
    {_, _, shot} = candidate = List.first(sorted_candidates)
    {shot, List.delete(candidates, candidate)}
  end

  defp sort_candidates(candidates, hit_stack) do
    targeting_direction = targeting_direction(hit_stack)

    candidates
    |> Enum.sort_by(fn({coordinate, _, _}) ->
      Enum.find_index(hit_stack, &(&1 == coordinate))
    end)
    |> Enum.sort_by(fn({_, direction, _}) ->
      if matches_targeting?(direction, targeting_direction), do: 0, else: 1
    end)
  end

  defp take_shot(state, shot, new_candidates) do
    %{state | candidates: new_candidates, last_shot: shot}
    |> Map.update!(:shots, &([shot|&1]))
    |> Map.update!(:remaining_coordinates, &(List.delete(&1, shot)))
  end

  defp create_probability_grid(tracking_board, remaining_ships) do
    valid_coordinates =
      tracking_board
      |> all_valid_ship_arrangements(remaining_ships)
      |> Enum.map(&(ship_coordinates(&1)))
      |> List.flatten
    Enum.reduce(valid_coordinates, Grid.new(10, 0), fn(coord, grid) ->
      Grid.update_at(grid, coord, &(&1 + 1))
    end)
  end

  defp all_valid_ship_arrangements(tracking_board, remaining_ships) do
    for ship <- remaining_ships,
        {x, y} <- all_coordinates,
        orientation <- [:across, :down],
        ship_fits?({x, y, ship, orientation}, tracking_board),
        do: {x, y, ship, orientation}
  end

  # Assume we are in hunting mode, and therefore consider :hit and :miss cells
  # to be equivalent. Without this assumption, a ship could fit even if some of
  # its coordinates are :hit.
  defp ship_fits?(ship, board) do
    Enum.all?(ship_coordinates(ship), fn(coord) ->
      Grid.on?(board, coord) && Grid.fetch!(board, coord) == :unknown
    end)
  end

  defp ship_coordinates({x, y, size, orientation}) do
    Enum.map(0..size-1, fn(n) ->
      case orientation do
        :across -> {x + n, y}
        :down -> {x, y + n}
      end
    end)
  end
end
