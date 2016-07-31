defmodule Battleship.Game do
  use GenServer
  alias Battleship.Board
  alias Battleship.PlayerProxy

  @type ship_length :: 2..5

  @type orientation :: :across | :down

  @type ship :: {
    non_neg_integer, # x coordinate
    non_neg_integer, # y coordinate
    ship_length,
    orientation
  }

  @type fleet_spec :: [ship_length]

  @type player :: GenServer.server

  @default_options [
    board_size: 10,
    fleet_spec: [5, 4, 3, 3, 2],
    move_delay: 10,
    round_delay: 1000
  ]

  ## API functions

  def start_link(players, opts \\ []) do
    GenServer.start_link(__MODULE__, [players, opts])
  end

  def start_game(game_server) do
    GenServer.call(game_server, :start_game)
  end

  def start_game(game_server, event_handlers) when is_list(event_handlers) do
    {:ok, manager} = GenEvent.start_link
    Enum.each(event_handlers, &(GenEvent.add_handler(manager, &1, self)))
    GenServer.cast(game_server, {:start_game, manager})
  end
  def start_game(game_server, event_handler) do
    start_game(game_server, [event_handler])
  end

  ## GenServer callbacks

  def init([players, options]) do
    opts = Keyword.merge(@default_options, options) |> Enum.into(%{})
    [player1, player2] = Enum.map(players, fn(player) ->
      board = Board.new(opts.board_size, opts.fleet_spec)
      %{
        ref: make_ref(),
        pid: player,
        name: PlayerProxy.name(player),
        board: board,
        remaining_ships: Board.remaining_ships(board)
      }
    end)

    state = Map.merge(opts, %{
      player1: player1,
      player2: player2,
      winner: nil,
      turn: 0
    })

    {:ok, state}
  end

  def handle_call(:start_game, _from, state) do
    new_state = setup_game(state)
    IO.puts("Game started. State: #{new_state}")
    new_state
  end

  def handle_cast({:start_game, event_manager}, state) do
    state
    |> Map.merge(%{event_manager: event_manager})
    |> setup_game
    |> handle_game_state
  end

  def handle_info(:tick, state) do
    state |> tick |> handle_game_state
  end

  ## Internal functions

  defp setup_game(state) do
    p1 = state.player1
    p2 = state.player2
    p1_ships = PlayerProxy.new_game(p1.pid)
    p2_ships = PlayerProxy.new_game(p2.pid)

    {p1_ok, p1_result} = Board.place_ships(p1.board, p1_ships)
    {p2_ok, p2_result} = Board.place_ships(p2.board, p2_ships)
    p1_good = (p1_ok == :ok)
    p2_good = (p2_ok == :ok)

    cond do
      p1_good && p2_good ->   # Both players made valid fleet arrangement
        notify(state.event_manager, :new_game, [p1, p2])
        state
        |> put_in([:player1, :board], p1_result)
        |> put_in([:player2, :board], p2_result)
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
    {player_key, opponent_key} = player_keys_for_turn(turn)
    player = state[player_key]
    opponent = state[opponent_key]

    coordinate = get_player_move(player.pid, opponent.board)

    if Board.legal_shot?(opponent.board, coordinate) do
      {shot_result, new_board} = Board.fire!(opponent.board, coordinate)
      winner = if Board.all_sunk?(new_board), do: player, else: nil

      move_info = %{
        by: player.name,
        target: coordinate,
        result: shot_result
      }
      new_state =
        %{state |
          turn: next_turn(turn),
          winner: winner
        }
        |> put_in([opponent_key, :board], new_board)
        |> put_in([opponent_key, :remaining_ships], Board.remaining_ships(new_board))

      notify(state.event_manager,
             :move,
             {move_info, [new_state.player1, new_state.player2]})

      new_state
    else
      notify(state.event_manager,
             :illegal_move,
             %{by: player.name, target: coordinate})
      %{state | winner: opponent}
    end

  end

  defp handle_game_state(state) do
    case state.winner do
      nil ->
        schedule_tick(state.move_delay)
        {:noreply, state}
      :nobody ->
        notify(state.event_manager, :game_over, :illegal_game)
        {:stop, :normal, state}
      player ->
        notify(state.event_manager, :game_over, %{winner: player})
        {:stop, :normal, state}
    end
  end

  defp schedule_tick(time) do
    Process.send_after(self, :tick, time)
  end

  # Returns a tuple with the player whose turn it is as the first element and
  # the opposing player as the second element.
  defp player_keys_for_turn(turn) when turn in 0..1 do
    case turn do
      0 -> {:player1, :player2}
      1 -> {:player2, :player1}
    end
  end

  defp get_player_move(player, opponent_board) do
    board_status = Board.status(opponent_board)
    remaining_ships = Board.remaining_ships(opponent_board)
    PlayerProxy.take_turn(player, board_status, remaining_ships)
  end

  defp next_turn(turn) do
    rem(turn + 1, 2)
  end

  defp notify(nil, _event, _data), do: nil
  defp notify(event_manager, event, data) do
    GenEvent.notify(event_manager, {event, data})
  end
end
