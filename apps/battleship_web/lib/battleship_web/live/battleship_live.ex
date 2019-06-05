defmodule BattleshipWeb.BattleshipLive do
  use Phoenix.LiveView
  @path Path.expand("../../apps/players/example")

  def mount(_session, socket) do
    {:ok, assign(socket, :game_msg, "")}
  end

  def render(assigns) do
    ~L"""
    <h1><%= @game_msg %></h1>
    <button phx-click="start-game">Start Game</button>
    """
  end

  def handle_event("start-game", _args, socket) do
    {:ok, game_pid} =
      Battleship.Game.Supervisor.start_game(
        @path <> "/linear.exs",
        @path <> "/random.exs",
        {Battleship.WebRenderer, self()}
      )

    Battleship.Game.start_game(game_pid)

    {:noreply, assign(socket, :game_msg, "Game started")}
  end

  def handle_info({:game_over, msg}, socket) do
    {:noreply, assign(socket, :game_msg, msg)}
  end

  def handle_info(payload, socket) do
    {:noreply, assign(socket, :game_msg, payload)}
  end
end
