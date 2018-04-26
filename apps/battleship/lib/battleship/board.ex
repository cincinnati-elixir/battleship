defmodule Battleship.Board do
  @moduledoc """
  Representation of (one player's side of) a board in the game of Battleship.
  """

  defstruct size: 0, fleet_spec: [], grid: nil, fleet: []

  @type size :: 3..100
  @type x_coordinate :: non_neg_integer
  @type y_coordinate :: non_neg_integer
  @type coordinate :: {x_coordinate, y_coordinate}

  @type board :: %__MODULE__{
          size: non_neg_integer,
          fleet_spec: [pos_integer],
          grid: Grid.t(),
          fleet: [Battleship.Game.ship()]
        }

  @typedoc "Describes the result of firing a shot."
  @type shot_result :: :hit | :miss | {:sunk, Battleship.Game.ship_length()}
  @type cell_status :: :hit | :miss | :unknown
  @type status :: [[cell_status]]

  defmodule IllegalMoveError do
    defexception message: "Illegal coordinates for move"
  end

  @doc """
  Creates a new board of the given `size` and `fleet_spec`.

  ## Parameters

      - size: The board will be a grid of `size × size`.
      - fleet_spec: A list specifying the lengths of the ships allowed on the board.

  ## Examples

      iex> board = Battleship.Board.new(10, [5, 4, 3, 3, 2])
      iex> board.size
      10
  """
  @spec new(size, Battleship.Game.fleet_spec()) :: board
  def new(size, fleet_spec) when size in 3..100 do
    cell = %{occupied?: false, shot?: false}
    grid = Grid.new(size, cell)
    %__MODULE__{size: size, fleet_spec: fleet_spec, grid: grid}
  end

  @doc """
  Attempt to arrange the given `ships` on the `board`.

  Returns `{:ok, board}` if successful, or `{:error, reason}` otherwise.
  """
  @spec place_ships(board, [Battleship.Game.ship()]) :: {:ok, board} | {:error, term}
  def place_ships(board, ships) when is_list(ships) do
    if valid_fleet_arrangement?(board, ships) do
      coordinates = Enum.map(ships, &ship_coordinates/1) |> List.flatten()

      new_grid =
        Enum.reduce(coordinates, board.grid, fn coordinate, grid ->
          cell = Grid.at(grid, coordinate)
          Grid.replace_at(grid, coordinate, %{cell | occupied?: true})
        end)

      new_board = %__MODULE__{board | grid: new_grid, fleet: ships}
      {:ok, new_board}
    else
      {:error, :invalid_fleet_arrangement}
    end
  end

  @doc """
  Representation of the tracking state of the board, as modified by the
  opposing player's shots. It is given as a list of lists; the inner
  lists represent horizontal rows. Each cell may be in one of three states:
  `:unknown`, `:hit`, or `:miss`. For example:

    [[:hit, :miss, :unknown, ...], [:unknown, :unknown, :unknown, ...], ...]
    # 0,0   1,0    2,0              0,1       1,1       2,1
  """
  @spec status(board) :: status
  def status(board) do
    status_grid =
      Grid.map(board.grid, fn cell ->
        if cell.shot? do
          if cell.occupied?, do: :hit, else: :miss
        else
          :unknown
        end
      end)

    Grid.to_list(status_grid)
  end

  @doc "Is `{x, y}` a legal shot coordinate for the `board`?"
  @spec legal_shot?(board, any) :: boolean
  def legal_shot?(board, {x, y}), do: on_board?(board, {x, y})
  def legal_shot?(_board, _), do: false

  @doc """
  Fire a shot at the given `coordinate` of the `board`. Returns a tuple
  containing the shot_result as the first element, and the updated board as the
  second element.

  Raises an `IllegalMoveError` if the `coordinate` is not on the board.
  """
  @spec fire!(board, coordinate) :: {shot_result, board}
  def fire!(board, coordinate = {_x, _y}) do
    if legal_shot?(board, coordinate) do
      new_grid =
        Grid.update_at(board.grid, coordinate, fn cell ->
          %{cell | shot?: true}
        end)

      new_board = %{board | grid: new_grid}
      {shot_result(new_board, coordinate), new_board}
    else
      raise IllegalMoveError
    end
  end

  @doc """
  Fires a shot at each coordinate in the list of `coordinates`. Returns the
  updated board.

  Raises an `IllegalMoveError` if any coordinate is not on the board.
  """
  @spec rapid_fire!(board, [coordinate]) :: board
  def rapid_fire!(board, coordinates) when is_list(coordinates) do
    Enum.reduce(coordinates, board, fn {x, y}, acc ->
      {_, new_board} = fire!(acc, {x, y})
      new_board
    end)
  end

  @doc """
  A list of the ships remaining on the `board`, given as a list of numbers
  representing their lengths, longest first.
  """
  @spec remaining_ships(board) :: Battleship.Game.fleet_spec()
  def remaining_ships(board) do
    result =
      Enum.reduce(board.fleet, [], fn ship, acc ->
        if ship_sunk?(board, ship) do
          acc
        else
          {_, _, length, _} = ship
          [length | acc]
        end
      end)

    result |> Enum.sort() |> Enum.reverse()
  end

  @doc "Have all the ships on `board` been sunk?"
  @spec all_sunk?(board) :: boolean
  def all_sunk?(board) do
    Enum.empty?(remaining_ships(board))
  end

  defp ship_sunk?(board, ship) do
    Enum.all?(ship_coordinates(ship), fn coord ->
      Grid.fetch!(board.grid, coord).shot?
    end)
  end

  @spec on_board?(board, coordinate) :: boolean
  defp on_board?(board, coordinate) do
    Grid.on?(board.grid, coordinate)
  end

  defp valid_fleet_arrangement?(board, ships) do
    ships_on_board?(board, ships) && non_overlapping_ships?(board, ships) &&
      ships_match_fleet_spec?(board, ships)
  end

  defp ships_on_board?(board, ships) do
    Enum.all?(ships, &ship_on_board?(board, &1))
  end

  defp ship_on_board?(board, ship) do
    Enum.all?(ship_coordinates(ship), &on_board?(board, &1))
  end

  defp non_overlapping_ships?(_board, ships) do
    coordinates = Enum.map(ships, &ship_coordinates/1) |> List.flatten()
    Enum.uniq(coordinates) == coordinates
  end

  defp ships_match_fleet_spec?(board, ships) do
    fleet = Enum.map(ships, fn {_x, _y, size, _orientation} -> size end)
    Enum.sort(fleet) == Enum.sort(board.fleet_spec)
  end

  defp ship_coordinates({x, y, size, orientation}) do
    Enum.map(0..(size - 1), fn n ->
      case orientation do
        :across -> {x + n, y}
        :down -> {x, y + n}
      end
    end)
  end

  defp shot_result(board, shot) do
    cell = Grid.fetch!(board.grid, shot)

    if cell.occupied? do
      {_, _, length, _} = ship = find_ship(board, shot)

      if ship_sunk?(board, ship) do
        {:sunk, length}
      else
        :hit
      end
    else
      :miss
    end
  end

  defp find_ship(board, coordinate) do
    Enum.find(board.fleet, fn ship ->
      Enum.member?(ship_coordinates(ship), coordinate)
    end)
  end
end
