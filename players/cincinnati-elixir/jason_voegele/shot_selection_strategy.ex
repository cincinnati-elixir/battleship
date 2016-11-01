defmodule JasonVoegele.ShotSelectionStrategy do
  @moduledoc """
  Utility functions useful for ShotSelectionStrategy implementations.
  """

  alias Battleship.Game
  alias Battleship.Board

  def all_coordinates, do: for x <- 0..9, y <- 0..9, do: {x, y}

  def last_shot(shots), do: List.first(shots)

  @spec shot_result(Grid.t,
                    Board.coordinate | nil,
                    Game.fleet_spec,
                    Game.fleet_spec) :: Board.shot_result
  def shot_result(_, nil, _, _), do: :miss
  def shot_result(tracking_board, shot, ships, prev_ships) do
    case prev_ships -- ships do
      [] ->
        Grid.at(tracking_board, shot)
      [ship_length] ->
        {:sunk, ship_length}
    end
  end

  def select_mode(_current_mode, :hit), do: :targeting
  def select_mode(current_mode, :miss), do: current_mode
  def select_mode(_current_mode, {:sunk, _}), do: :hunting

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

  def possible_ship_coordinates(grid, {x, y} = coordinate) do
    candidates = [
      {coordinate, :up,    {x, y-1}},
      {coordinate, :down,  {x, y+1}},
      {coordinate, :left,  {x-1, y}},
      {coordinate, :right, {x+1, y}},
    ]
    for {_, _, coord} = candidate <- candidates,
        Grid.on?(grid, coord),
        Grid.fetch!(grid, coord) == :unknown,
        do: candidate
  end

  def matches_targeting?(direction, :vertical) do
    direction in [:up, :down, :north, :south]
  end
  def matches_targeting?(direction, :horizontal) do
    direction in [:left, :right, :west, :east]
  end
  def matches_targeting?(_, nil), do: true
end
