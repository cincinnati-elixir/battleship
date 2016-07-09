defmodule BoardTest do
  use ExUnit.Case
  doctest Battleship.Board
  alias Battleship.Board

  setup do
    board_size = 10
    fleet_spec = [5, 4, 3, 3, 2]
    empty_board = Board.new(board_size, fleet_spec)
    {:ok, board} = Board.place_ships(empty_board, valid_fleet)
    [board_size: board_size, fleet_spec: fleet_spec, empty_board: empty_board,
     board: board]
  end

  def valid_fleet do
    [ {0, 0, 5, :across},
      {0, 1, 4, :across},
      {0, 2, 3, :across},
      {0, 3, 3, :across},
      {0, 4, 2, :across} ]
  end

  def hits do
    [
      [{0,0}, {1,0}, {2,0}, {3,0}, {4,0}],
      [{0,1}, {1,1}, {2,1}, {3,1}],
      [{0,2}, {1,2}, {2,2}],
      [{0,3}, {1,3}, {2,3}],
      [{0,4}, {1,4}]
    ]
  end

  def initial_status do
    Grid.new(10, :unknown)
  end

  test "place_ships with valid fleet", context do
    assert {:ok, board} = Board.place_ships(context.empty_board, valid_fleet)
    assert context.fleet_spec == Board.remaining_ships(board)
  end

  test "place_ships with too few ships", context do
    assert {:error, _} = Board.place_ships(context.empty_board, tl(valid_fleet))
  end

  test "place_ships with too many ships", context do
    fleet = [{0, 5, 2, :across}|valid_fleet()]
    assert {:error, _} = Board.place_ships(context.empty_board, fleet)
  end

  test "place_ships with ships of wrong length", context do
    fleet = Enum.map(valid_fleet, fn({x, y, len, orientation}) ->
      {x, y, len * 2, orientation}
    end)
    assert {:error, _} = Board.place_ships(context.empty_board, fleet)
  end

  test "place_ships with ships off board", context do
    fleet = List.replace_at(valid_fleet, 0, {0, 11, 5, :across})
    assert {:error, _} = Board.place_ships(context.empty_board, fleet)
  end

  test "place_ships with overlapping ships", context do
    fleet = List.replace_at(valid_fleet, 0, {0, 0, 5, :down})
    assert {:error, _} = Board.place_ships(context.empty_board, fleet)
  end

  test "initial status is all unknown", context do
    assert Grid.to_list(initial_status) == Board.status(context.empty_board)
  end

  test "status after one hit", context do
    board = Board.fire!(context.board, {1,4})
    expected = Grid.replace_at(initial_status, {1,4}, :hit)
    assert Grid.to_list(expected) == Board.status(board)
  end

  test "status after one miss", context do
    board = Board.fire!(context.board, {2,4})
    expected = Grid.replace_at(initial_status, {2,4}, :miss)
    assert Grid.to_list(expected) == Board.status(board)
  end

  test "status after a few shots", context do
    shots = [{0,4}, {1,4}] ++ [{9,8}, {9,9}]
    board = Board.rapid_fire!(context.board, shots)

    expected = Grid.map(initial_status, fn(elem, coord) ->
      cond do
        coord in [{0,4}, {1,4}] ->
          :hit
        coord in [{9,8}, {9,9}] ->
          :miss
        true ->
          elem
      end
    end)

    assert Grid.to_list(expected) == Board.status(board)
  end

  test "status after sinking all the ships with perfect play", context do
    all_hits = List.flatten(hits)
    board = Board.rapid_fire!(context.board, all_hits)

    expected = Grid.map(initial_status, fn(elem, coord) ->
      if coord in all_hits do
        :hit
      else
        elem
      end
    end)

    assert Grid.to_list(expected) == Board.status(board)
    assert Board.all_sunk?(board)
  end

  test "remaining_ships in initial state", context do
    assert Board.remaining_ships(context.board) == context.fleet_spec
  end

  test "remaining_ships after hitting (but not sinking) some ships", context do
    shots = Enum.map(hits, &(tl(&1))) |> List.flatten
    board = Board.rapid_fire!(context.board, shots)
    assert Board.remaining_ships(board) == context.fleet_spec
  end

  test "remaining_ships after sinking one ship", context do
    shots = List.first(hits)
    board = Board.rapid_fire!(context.board, shots)
    assert Board.remaining_ships(board) == tl(context.fleet_spec)
  end

  test "remaining_ships after sinking all of the ships", context do
    shots = List.flatten(hits)
    board = Board.rapid_fire!(context.board, shots)
    assert Board.remaining_ships(board) == []
  end
end

