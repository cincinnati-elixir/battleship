defmodule Grid do
  @moduledoc """
  Facilities for creating and manipulating two dimensional square grids.
  Grids are composed of cells which contain elements and are identified by
  coordinates, which are tuples of the form `{x, y}` where `x` identifies the
  column and `y` identifies the row. Coordinates begin at {0, 0}, which is the
  top-left corner of the grid, and range up to {size-1, size-1}, which is the
  bottom-right corner.
  """

  defstruct size: 0, contents: []

  @type element :: Enum.element()
  @type default :: Enum.default()

  @typedoc """
  A coordinate identifying a cell in the grid.

  The first element in the tuple, `x`, identifies the column while the second
  element, `y`, identifies the row.
  """
  @type coordinate :: {non_neg_integer, non_neg_integer}

  @type index :: non_neg_integer

  @opaque t :: %Grid{
            size: non_neg_integer,
            contents: [[element]]
          }

  @doc """
  Creates a square grid of the given `size` with each cell containing the
  specified `init_value`.
  """
  @spec new(non_neg_integer, element) :: t
  def new(size, init_value \\ nil) when size >= 0 do
    %Grid{
      size: size,
      contents: List.duplicate(init_value, size) |> List.duplicate(size)
    }
  end

  @doc """
  Creates a square grid from the given list of lists.

  The `list` argument must be square, meaning that if there are N inner lists,
  each of them must have length == N.

  If the list is square, this function returns `{:ok, grid}`. Otherwise,
  returns `{:error, reason}`.
  """
  @spec from_list([[element]]) :: {:ok, t} | {:error, term}
  def from_list(list) do
    if square?(list) do
      {:ok, %Grid{size: length(list), contents: list}}
    else
      {:error, "List is not a square grid"}
    end
  end

  defp square?(list) when is_list(list) do
    size = length(list)
    Enum.all?(list, fn row -> is_list(row) && length(row) == size end)
  end

  defp square?(_not_a_list), do: false

  @doc """
  Creates a square grid from the given `flat_list`.

  The flat list must be able to be converted into a square grid by "chunking"
  the list by the square root of its length. In other words, the length of the
  list must have an integer square root.

  If the flat list can be converted into a square grid, this function returns
  `{:ok, grid}`. Otherwise, returns `{:error, reason}`.
  """
  @spec from_flat_list([element]) :: {:ok, t} | {:error, term}
  def from_flat_list(flat_list) do
    case squared(flat_list) do
      :error ->
        {:error, "List cannot be made into a square grid"}

      {size, chunked} ->
        {:ok, %Grid{size: size, contents: chunked}}
    end
  end

  defp squared(flat_list) do
    sqrt = round(:math.sqrt(length(flat_list)))
    chunked = Enum.chunk(flat_list, sqrt)

    if flat_list == List.flatten(chunked) do
      {sqrt, chunked}
    else
      :error
    end
  end

  @doc """
  Returns the size of the grid.

  Note that the size of the grid is the size of one side of the square grid.
  This is distinct from the count returned by `count/1`, which is the square
  of the grid size. In other words, if size is `N` then count is `N * N`.
  """
  @spec size(t) :: non_neg_integer
  def size(%Grid{size: size}) do
    size
  end

  @doc """
  Returns the number of cells in the grid. Since grids are two dimensional and
  square, the count is by definition the square of the size specified when
  the grid was created by `new`.

  ## Examples

      iex> Grid.count(Grid.new(4))
      16
      iex> Grid.count(Grid.new(7, :foo))
      49
  """
  @spec count(t) :: pos_integer
  def count(%Grid{size: size}) do
    size * size
  end

  @doc """
  Is the given `coordinate` on the grid?

      iex> Grid.on?(Grid.new(3), {2, 2})
      true
      iex> Grid.on?(Grid.new(3), {2, 3})
      false
  """
  @spec on?(t, coordinate) :: boolean
  def on?(%Grid{size: s}, {x, y}) do
    size = 0..(s - 1)
    x in size && y in size
  end

  @doc """
  Returns the element at the given {x, y} `coordinate`.

  Returns `default` if `coordinate` is out of bounds.

  ## Examples

      iex> Grid.at(Grid.new(3, :foo), {1, 2})
      :foo
      iex> Grid.at(Grid.new(3), {4, 4}, :default)
      :default
  """
  @spec at(t, coordinate, default) :: element | default
  def at(%Grid{} = grid, coordinate, default \\ nil) do
    case fetch(grid, coordinate) do
      {:ok, val} -> val
      :error -> default
    end
  end

  @doc """
  Finds the element at the given {x, y} `coordinate`. Returns `{:ok, element}`
  if found, otherwise `:error`.

  ## Examples

      iex> Grid.fetch(Grid.new(3, :foo), {1, 2})
      {:ok, :foo}
      iex> Grid.fetch(Grid.new(3), {4, 4})
      :error
  """
  @spec fetch(t, coordinate) :: {:ok, element} | :error
  def fetch(%Grid{} = grid, coordinate) do
    if on?(grid, coordinate) do
      {:ok, fetch!(grid, coordinate)}
    else
      :error
    end
  end

  @doc """
  Returns the element at the given {x, y} `coordinate`.

  Raises `Enum.OutOfBoundsError` if the given `coordinate` is outside the range
  of the grid.

  ## Examples

      iex> Grid.fetch!(Grid.new(3, :foo), {1, 2})
      :foo
      iex> Grid.fetch!(Grid.new(3), {4, 4})
      ** (Enum.OutOfBoundsError) out of bounds error
  """
  @spec fetch!(t, coordinate) :: element
  def fetch!(grid, coordinate)

  def fetch!(%Grid{contents: grid}, {x, y}) do
    grid |> Enum.fetch!(y) |> Enum.fetch!(x)
  end

  @doc """
  Returns a grid with a replaced value at the specified `coordinate`.

  Raises `Enum.OutOfBoundsError` if the given `coordinate` is outside the range
  of the grid.
  """
  @spec replace_at(t, coordinate, element) :: t
  def replace_at(grid, {x, y}, value) do
    update_at(grid, {x, y}, fn _ -> value end)
  end

  @doc """
  Returns a grid with the element at the given `coordinate` replaced by the
  value returned by the given `function`
  """
  @spec update_at(t, coordinate, (element -> element)) :: t
  def update_at(grid, {x, y}, function) do
    assert_on!(grid, {x, y})
    contents = grid.contents

    new_row =
      contents
      |> Enum.at(y)
      |> List.update_at(x, function)

    %{grid | contents: List.replace_at(contents, y, new_row)}
  end

  @doc """
  Returns a flat list with each element in the grid wrapped in a tuple
  alongside its coordinate.

  ## Examples

      iex> {:ok, grid} = Grid.from_list([[1,2],[3,4]])
      iex> Grid.with_coordinate(grid)
      [{1, {0, 0}}, {2, {1, 0}}, {3, {0, 1}}, {4, {1, 1}}]
  """
  @spec with_coordinate(t) :: [{element, coordinate}]
  def with_coordinate(%Grid{size: size} = grid) do
    grid
    |> Enum.with_index()
    |> Enum.map(fn {e, i} -> {e, index_to_coordinate(size, i)} end)
  end

  @doc """
  Returns a new grid where each cell is the result of invoking `fun` on each
  corresponding cell of `grid`.

  The `fun` must be of either arity 1 or arity 2. If it is arity 1, then it is
  passed just the element contained in each cell. If it is arity 2, then it is
  passed the element as the first argument and the second argument is the
  coordinate in `{x, y}` form.
  """
  @spec map(t, (element -> element) | (element, coordinate -> element)) :: t
  def map(grid, fun) do
    arity = :erlang.fun_info(fun)[:arity]

    new_contents =
      if arity == 2 do
        Enum.map(with_coordinate(grid), fn {elem, coordinate} ->
          fun.(elem, coordinate)
        end)
      else
        Enum.map(to_flat_list(grid), fun)
      end

    {:ok, new_grid} = from_flat_list(new_contents)
    new_grid
  end

  @doc """
  Returns a list of lists containing the contents of `grid`.

  ## Examples

      iex> Grid.to_list(Grid.new(2, 0))
      [[0, 0], [0, 0]]
  """
  @spec to_list(t) :: [[element]]
  def to_list(grid) do
    grid.contents
  end

  @doc """
  Returns a flattened list containing the contents of `grid`.

  The list returned is built from the top-left corner and proceeds
  left-to-right and downward such that the index of the last element in the
  list will be at index `count(grid) - 1`.

  See also `coordinate_to_index/1` and `index_to_coordinate/2`.

  ## Examples

      iex> Grid.to_flat_list(Grid.new(2, 0))
      [0, 0, 0, 0]
  """
  @spec to_flat_list(t) :: [element]
  def to_flat_list(grid) do
    List.flatten(to_list(grid))
  end

  @doc """
  Converts the grid `coordinate` to the equivalent `index` for a flattened
  list representation of a grid. The top-left cell {0, 0} is index 0, and
  the index is effectively the sum of of `x` and `y` in the given `coordinate`.

  ## Examples

      iex> Grid.coordinate_to_index({0, 0})
      0
      iex> Grid.coordinate_to_index({4, 1})
      5
  """
  @spec coordinate_to_index(coordinate) :: index
  def coordinate_to_index({x, y}) do
    x + y
  end

  @doc """
  Converts an `index` (as used for a flattened list representation of a grid)
  to the equivalent `coordinate` for a square grid of the specified `size`.
  The `index` must be less than size of the grid square, i.e. `size * size`.

  ## Examples

      iex> Grid.index_to_coordinate(3, 1)
      {1, 0}
      iex> Grid.index_to_coordinate(3, 5)
      {2, 1}
      iex> Grid.index_to_coordinate(3, 8)
      {2, 2}
      iex> Grid.index_to_coordinate(3, 9)
      ** (FunctionClauseError) no function clause matching in Grid.index_to_coordinate/2
  """
  @spec index_to_coordinate(t | non_neg_integer, index) :: coordinate
  def index_to_coordinate(size, index) when index < size * size do
    {rem(index, size), div(index, size)}
  end

  def index_to_coordinate(%Grid{size: size}, index) do
    index_to_coordinate(size, index)
  end

  defp assert_on!(grid, coordinate) do
    unless on?(grid, coordinate) do
      raise Enum.OutOfBoundsError
    end
  end
end

defimpl Enumerable, for: Grid do
  def count(grid), do: {:ok, Grid.count(grid)}

  def member?(_grid, _value), do: {:error, __MODULE__}

  def reduce(grid, acc, fun) do
    do_reduce(Grid.to_flat_list(grid), acc, fun)
  end

  defp do_reduce(_, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  defp do_reduce([], {:cont, acc}, _fun) do
    {:done, acc}
  end

  defp do_reduce([h | t], {:cont, acc}, fun) do
    do_reduce(t, fun.(h, acc), fun)
  end

  defp do_reduce(grid, {:suspend, acc}, fun) do
    {:suspended, acc, &do_reduce(grid, &1, fun)}
  end
end
