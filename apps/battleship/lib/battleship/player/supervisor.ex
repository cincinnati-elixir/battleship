defmodule Battleship.Player.Supervisor do
  use Supervisor

  @type player_id :: binary
  @type player_module :: module | binary

  def start_link(restart \\ :transient) do
    Supervisor.start_link(__MODULE__, [restart])
  end

  def init([restart]) do
    children = [worker(Battleship.Player, [], restart: restart)]
    # We don't want an errant player implementation to crash the supervisor
    # so set `max_restarts` to a high value and allow the supervisor to restart
    # the player process as much as needed. If a player process crashes that
    # causes the current game to be finished with the opposing player as the winner.
    supervise(children, strategy: :simple_one_for_one, max_restarts: 1000)
  end

  @spec start_player(pid, player_module) :: player_id
  def start_player(supervisor_pid, player_module) when is_atom(player_module) do
    player_id = generate_player_id()
    {:ok, _player_pid} = Supervisor.start_child(supervisor_pid, [player_module, player_id])
    player_id
  end
  def start_player(supervisor_pid, player_module) when is_binary(player_module) do
    player_module = if String.ends_with?(player_module, ".exs") do
      [{player_module, _code}] = Code.load_file(player_module)
      player_module
    else
      String.to_atom("Elixir." <> player_module)
    end
    start_player(supervisor_pid, player_module)
  end

  @spec start_players(pid, [player_module]) :: [player_id]
  def start_players(supervisor_pid, player_modules) when is_list(player_modules) do
    Enum.map(player_modules, &(start_player(supervisor_pid, &1)))
  end

  defp generate_player_id do
    UUID.uuid1()
  end
end
