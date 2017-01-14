defmodule Battleship.Game.Supervisor do
  use Supervisor

  @name __MODULE__

  alias Battleship.Player.Supervisor, as: PlayerSupervisor

  def start_link do
    Supervisor.start_link(@name, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      worker(Battleship.Game, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  # TODO: We now use registered UUIDs instead of PIDs for identifying player processes.
  #       Figure out how to make this function work with UUIDs, or delete it.
  def start_game(player1, player2, event_handlers) when is_pid(player1) and is_pid(player2) do
    event_manager = start_event_manager(event_handlers)
    game_opts = [event_manager: event_manager]
    Supervisor.start_child(@name, [[player1, player2], game_opts])
  end

  def start_game(player1_module, player2_module, event_handlers) do
    # start_game(start_player(player1_module), start_player(player2_module), event_handlers)
    {:ok, player_sup} = PlayerSupervisor.start_link(:temporary)
    players = PlayerSupervisor.start_players(player_sup, [player1_module, player2_module])
    event_manager = start_event_manager(event_handlers)
    game_opts = [event_manager: event_manager]
    Supervisor.start_child(@name, [players, game_opts])
  end

  def start_match(player1_module, player2_module, num_games, event_handlers) do
    {:ok, player_sup} = PlayerSupervisor.start_link(:permanent)
    players = PlayerSupervisor.start_players(player_sup, [player1_module, player2_module])
    event_manager = start_event_manager(event_handlers)
    game_opts = [
      event_manager: event_manager,
      move_delay: 0,
      round_delay: 0
    ]
    GenEvent.notify(event_manager, {:start_match, zip_player_names(players), num_games})
    for i <- 1..num_games do
      {:ok, game_pid} = Supervisor.start_child(@name, [players, game_opts])
      ref = Process.monitor(game_pid)
      Battleship.Game.start_game(game_pid)
      wait_for_exit(ref)
    end
    GenEvent.notify(event_manager, :match_over)
  end

  @spec zip_player_names([PlayerSupervisor.player_id]) :: [{PlayerSupervisor.player_id, String.t}]
  defp zip_player_names(players) when is_list(players) do
    Enum.map(players,
             fn(player_id) ->
               {:ok, name} = Battleship.Player.name(player_id)
               {player_id, name}
             end)
  end

  defp start_event_manager(event_handlers) when is_list(event_handlers) do
    {:ok, manager} = GenEvent.start_link
    Enum.each(event_handlers, &(add_event_handler(manager, &1)))
    manager
  end
  defp start_event_manager(event_handler) do
    start_event_manager([event_handler])
  end

  defp add_event_handler(manager, {module, args}) do
    GenEvent.add_handler(manager, module, args)
  end
  defp add_event_handler(manager, module) do
    add_event_handler(manager, {module, self})
  end

  defp wait_for_exit(pid) when is_pid(pid) do
    ref = Process.monitor(pid)
    wait_for_exit(ref)
  end
  defp wait_for_exit(ref) when is_reference(ref) do
    receive do
      {:DOWN, ref, :process, from_pid, reason} ->
        reason
    end
  end
end
