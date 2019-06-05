defmodule Battleship.Game do
  use GenServer
  alias Battleship.Board
  alias Battleship.Player

  @type ship_length :: 2..5

  @type orientation :: :across | :down

  @type ship :: {
          # x coordinate
          non_neg_integer,
          # y coordinate
          non_neg_integer,
          ship_length,
          orientation
        }

  @type fleet_spec :: [ship_length]

  @type player :: GenServer.server()

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
    GenServer.cast(game_server, :start_game)
  end

  ## GenServer callbacks

  def init([[player1, player2], options]) do
    opts = Keyword.merge(@default_options, options) |> Enum.into(%{})

    state =
      Map.merge(opts, %{
        player1_pid: player1,
        player2_pid: player2,
        winner: nil,
        turn: 0,
        game_over: false
      })

    {:ok, state}
  end

  def handle_call(:start_game, _from, state) do
    new_state = setup_game(state)
    IO.puts("Game started. State: #{new_state}")
    new_state
  end

  def handle_cast(:start_game, state) do
    state
    |> setup_game
    |> handle_game_state
  end

  def handle_info(:tick, state) do
    state |> tick |> handle_game_state
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    IO.puts(Process.group_leader(), "***** Got DOWN message:")
    IO.inspect(ref)
    p1_ref = state.player1.monitor_ref
    p2_ref = state.player2.monitor_ref

    winner =
      case ref do
        ^p1_ref ->
          state.player2

        ^p2_ref ->
          state.player1
      end

    handle_game_state(%{state | game_over: true, winner: winner})
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ## Internal functions

  defp setup_game(state) do
    state = setup_players(state)
    p1 = state.player1
    p2 = state.player2

    {p1_ok, p1_result} = new_game(p1)
    {p2_ok, p2_result} = new_game(p2)
    p1_good = p1_ok == :ok
    p2_good = p2_ok == :ok

    cond do
      # Both players made valid fleet arrangement
      p1_good && p2_good ->
        notify(state.event_manager, :new_game, [p1, p2])

        state
        |> put_in([:player1, :monitor_ref], Battleship.Player.monitor(p1.pid))
        |> put_in([:player2, :monitor_ref], Battleship.Player.monitor(p2.pid))
        |> put_in([:player1, :board], p1_result)
        |> put_in([:player2, :board], p2_result)

      # Player 1 loses
      !p1_good && p2_good ->
        %{state | winner: p2}

      # Player 2 loses
      p1_good && !p2_good ->
        %{state | winner: p1}

      # Illegal game
      !p1_good && !p2_good ->
        %{state | winner: :nobody}
    end
  end

  defp setup_players(state) do
    game_opts = Map.take(state, [:board_size, :fleet_spec])

    state
    |> Map.put(:player1, create_player(state.player1_pid, game_opts))
    |> Map.put(:player2, create_player(state.player2_pid, game_opts))
  end

  defp create_player(player_pid, opts) do
    case Player.name(player_pid) do
      {:ok, name} ->
        board = Board.new(opts.board_size, opts.fleet_spec)

        %{
          pid: player_pid,
          name: name,
          board: board,
          remaining_ships: Board.remaining_ships(board),
          shots: []
        }

      {:error, _} ->
        :error
    end
  end

  defp new_game(:error), do: {:error, :invalid_player}

  defp new_game(player) do
    case Player.new_game(player.pid) do
      {:ok, ships} ->
        Board.place_ships(player.board, ships)

      error ->
        error
    end
  end

  defp tick(state) do
    {player_key, opponent_key} = player_keys_for_turn(state.turn)
    player = state[player_key]
    opponent = state[opponent_key]

    handle_player_turn(
      state,
      {player_key, player},
      {opponent_key, opponent},
      get_player_move(player.pid, opponent.board)
    )
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

  defp handle_player_turn(state, {_, player}, {_, opponent}, {:error, error}) do
    game_over_reason = "#{player.name} crashed."
    %{state | game_over: game_over_reason, winner: opponent}
  end

  defp handle_player_turn(
         state,
         {player_key, player},
         {opponent_key, opponent},
         {:ok, coordinate}
       ) do
    if Board.legal_shot?(opponent.board, coordinate) do
      {shot_result, new_board} = Board.fire!(opponent.board, coordinate)

      move_info = %{
        by: player.name,
        target: coordinate,
        result: shot_result
      }

      new_state =
        %{state | turn: next_turn(state.turn)}
        |> update_in([player_key, :shots], &[coordinate | &1])
        |> put_in([opponent_key, :board], new_board)
        |> put_in([opponent_key, :remaining_ships], Board.remaining_ships(new_board))
        |> set_winner(Board.all_sunk?(new_board), player)

      notify(state.event_manager, :move, {move_info, [new_state.player1, new_state.player2]})

      new_state
    else
      notify(state.event_manager, :illegal_move, %{by: player.name, target: coordinate})
      %{state | winner: opponent}
    end
  end

  defp set_winner(state, false, _player), do: state

  defp set_winner(state, true, player) do
    %{state | game_over: true, winner: player}
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
    Player.take_turn(player, board_status, remaining_ships)
  end

  defp next_turn(turn) do
    rem(turn + 1, 2)
  end

  defp notify(nil, _event, _data), do: nil

  defp notify(event_manager, event, data) do
    GenEvent.notify(event_manager, {event, data})
  end
end
