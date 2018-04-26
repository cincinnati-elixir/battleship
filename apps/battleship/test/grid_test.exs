defmodule GridTest do
  use ExUnit.Case
  doctest Grid

  test "new with valid size" do
    assert Grid.count(Grid.new(4)) == 16
    assert Grid.count(Grid.new(4, false)) == 16
    assert Grid.count(Grid.new(4, 42)) == 16
  end

  test "new with invalid size" do
    assert_raise FunctionClauseError, fn -> Grid.new(-1) end
    assert_raise FunctionClauseError, fn -> Grid.new(-1, 42) end
  end

  test "from_list with square list" do
    list = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    {:ok, grid} = Grid.from_list(list)
    assert Grid.size(grid) == 3
    assert Grid.to_list(grid) == list
  end

  test "from_list with non-square list" do
    list = [[1, 2, 3], [4, 5, 6]]
    assert {:error, _reason} = Grid.from_list(list)
  end

  test "from_flat_list with squarable list" do
    list = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    {:ok, grid} = Grid.from_flat_list(list)
    assert Grid.count(grid) == 9
    assert Grid.size(grid) == 3
    assert Grid.to_flat_list(grid) == list
  end

  test "from_flat_list with non-squarable list" do
    list = [1, 2, 3, 4, 5, 6, 7, 8]
    assert {:error, _reason} = Grid.from_list(list)
  end

  test "on?" do
    grid = Grid.new(3)
    assert Grid.on?(grid, {0, 0})
    assert Grid.on?(grid, {2, 2})
    refute Grid.on?(grid, {3, 3})
    refute Grid.on?(grid, {2, 3})
    refute Grid.on?(grid, {-1, 1})
  end

  test "fetch! with valid coordinates" do
    assert 42 == Grid.fetch!(Grid.new(3, 42), {1, 2})
  end

  test "fetch! with invalid coordinates" do
    assert_raise Enum.OutOfBoundsError, fn ->
      Grid.fetch!(Grid.new(3), {2, 3})
    end
  end

  test "replace_at" do
    grid = Grid.new(3) |> Grid.replace_at({1, 1}, 4)
    assert(Grid.at(grid, {1, 1}) == 4)

    assert_raise Enum.OutOfBoundsError, fn ->
      Grid.replace_at(grid, {9, 9}, 9)
    end
  end

  test "update_at" do
    grid = Grid.new(3, 5) |> Grid.update_at({1, 1}, &(&1 * &1))
    assert(Grid.at(grid, {1, 1}) == 25)

    assert_raise Enum.OutOfBoundsError, fn ->
      Grid.update_at(grid, {9, 9}, & &1)
    end
  end

  test "map with arity-1 fun" do
    {:ok, grid} = Grid.from_list([[1, 2], [3, 4]])
    new_grid = Grid.map(grid, fn e -> e * e end)
    assert Grid.to_list(new_grid) == [[1, 4], [9, 16]]
  end

  test "map with arity-2 fun" do
    {:ok, grid} = Grid.from_list([[1, 2], [3, 4]])
    new_grid = Grid.map(grid, fn e, {x, y} -> e + x + y end)
    assert Grid.to_list(new_grid) == [[1, 3], [4, 6]]
  end

  test "enumerable" do
    grid = Grid.new(3, 2)
    assert Enum.all?(grid, fn val -> val == 2 end)
  end
end
