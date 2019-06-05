defmodule BattleshipWeb.PageController do
  use BattleshipWeb, :controller

  def index(conn, _params) do
    Phoenix.LiveView.Controller.live_render(conn, BattleshipWeb.BattleshipLive, session: %{})
  end
end
