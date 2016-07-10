defmodule Battleship.Game do
  use GenServer
  alias Battleship.PlayerProxy

  @type ship_length :: 2..5

  @type orientation :: :across | :down

  @type ship :: {
    non_neg_integer, # x coordinate
    non_neg_integer, # y coordinate
    ship_length,
    orientation
  }

  @type fleet :: [ship_length]

  @type player :: module | GenServer.server

  @default_options [
    board_size: 10,
    fleet_spec: [5, 4, 3, 3, 2],
    move_delay: 100,
    round_delay: 1000
  ]

  ## API functions

  def start_link(players, opts \\ []) do
    GenServer.start_link(__MODULE__, [players, opts])
  end

  def start_game(game_server) do
    GenServer.call(game_server, :start_game)
  end

  def start_game(game_server, event_handler) do

  end

  ## GenServer callbacks

  def init([players, options]) do
    opts = Keyword.merge(@default_options, options) |> Enum.into(%{})
    player_pids = Enum.map(players, &player_pid/1)
    boards = create_boards(2, opts.board_size, opts.fleet_spec)

    state = %{opts |
      actors: Enum.zip(player_pids, boards),
      winner: nil,
      turn: 0
    }
    {:ok, state}
  end

  def handle_cast(:start_game, state) do
    new_state = setup_game(state)
    handle_game_state(new_state)
  end

  def handle_info(:tick, state) do
    new_state = tick(state)
    handle_game_state(new_state)
  end

  ## Internal functions

  defp handle_game_state(state) do
    if state.winner do
    else
      schedule_tick(state.move_delay)
    end
  end

  defp schedule_tick(time) do
    Process.send_after(self, :tick, time)
  end

  defp setup_game(state) do
    [{p1, b1}, {p2, b2}] = state.actors
    p1_ships = PlayerProxy.new_game(p1)
    p2_ships = PlayerProxy.new_game(p2)
    {p1_ok, p1_result} = Battleship.Board.place_ships(b1, p1_ships)
    {p2_ok, p2_result} = Battleship.Board.place_ships(b2, p2_ships)
    p1_good = (p1_ok == :ok)
    p2_good = (p2_ok == :ok)

    cond do
      p1_good && p2_good ->   # Both players made valid fleet arrangement
        %{state | actors: [{p1, p1_result}, {p2, p2_result}]}
      !p1_good && p2_good ->  # Player 1 loses
        %{state | winner: p2}
      p1_good && !p2_good ->  # Player 2 loses
        %{state | winner: p1}
      !p1_good && !p2_good -> # Illegal game
        %{state | winner: :nobody}
    end
  end

  defp tick(state) do
    turn = state.turn
    {player, opponent_board} =
      get_player_and_board_for_turn(state.actors, turn)

    coordinate = get_player_move(player, opponent_board)

    new_board = Battleship.Board.fire!(opponent_board, coordinate)
    winner = if Battleship.Board.all_sunk?(opponent_board) do
      player
    else
      nil
    end

    %{state |
      turn: next_turn(turn),
      winner: winner,
      actors: update_opponent_board(state.actors, new_board, turn)
    }
  end

  defp get_player_and_board_for_turn(actors, turn) when turn in 0..1 do
    [{p1, b1}, {p2, b2}] = actors
    case turn do
      0 -> {p1, b2}
      1 -> {p2, b1}
    end
  end

  defp get_player_move(player, opponent_board) do
    board_status = Battleship.Board.status(opponent_board)
    remaining_ships = Battleship.Board.remaining_ships(opponent_board)
    PlayerProxy.take_turn(player, board_status, remaining_ships)
  end

  defp update_opponent_board(actors, new_board, turn) when turn in 0..1 do
    List.update_at(actors,
                   next_turn(turn),
                   fn({player, _board}) -> {player, new_board} end)
  end

  defp next_turn(turn) do
    rem(turn + 1, 2)
  end

  defp player_pid(player) when is_pid(player), do: player
  defp player_pid(player) do
    apply(player, :start_link, [])
  end

  defp create_boards(num_boards, size, fleet) do
    List.duplicate(fn(_) -> Battleship.Board.new(size, fleet) end, num_boards)
  end
end
