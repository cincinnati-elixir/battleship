defmodule Battleship.WebRenderer do
  use GenEvent
  use Dye

  alias Battleship.Board

  ## GenEvent callbacks

  def init(web_listener) do
    {:ok, web_listener}
  end

  def handle_event({:new_game, game_state}, web_listener) do
    [player1, player2] = game_state
    render(player1, player2)
    {:ok, web_listener}
  end

  def handle_event({:game_over, :illegal_game}, web_listener) do
    print("GAME ERROR - both players disqualified")
    send(web_listener, :game_over)
    {:ok, web_listener}
  end

  def handle_event({:game_over, %{winner: player}}, web_listener) do
    shot_count = length(player.shots)
    message = "GAME OVER - #{player.name} wins! (#{shot_count} moves)"
    send(web_listener, {:game_over, message})
    {:ok, web_listener}
  end

  def handle_event({:move, {move_info, game_state}}, web_listener) do
    [player1, player2] = game_state
    render(player1, player2)
    # speak_result(move_info.result)
    {:ok, web_listener}
  end

  def handle_event({:illegal_move, move_info}, web_listener) do
    print("ILLEGAL MOVE by #{move_info.by}: #{inspect(move_info.target)}")
    {:ok, web_listener}
  end

  @reset "\e[2J\e[H"

  defp icon(:unknown), do: ~s"· "
  defp icon(:hit), do: ~s"█▉"r
  defp icon(:miss), do: ~s"▒▒"c

  defp render(player1, player2) do
    {:ok, io} = StringIO.open("")
    IO.write(io, @reset)
    payload = render(io, player1.name, Board.status(player1.board), player1.remaining_ships)
    IO.puts(io, "")
    payload = render(io, player2.name, Board.status(player2.board), player2.remaining_ships)
    {_, output} = StringIO.contents(io)
    StringIO.close(io)
    print(output)
  end

  defp render(output, name, board, remaining_ships) do
    IO.puts(output, ~s"#{name}\n"Du)
    pad = length(board) - length(remaining_ships)
    padded_remaining_ships = remaining_ships ++ List.duplicate(0, pad)

    Enum.each(Enum.zip(board, padded_remaining_ships), fn {row, ship} ->
      line = render_row(row) <> " " <> render_ship(ship)
      IO.puts(output, line)
    end)
  end

  defp render_ship(length) when length in 1..5 do
    List.duplicate("█▉", length) |> Enum.join()
  end

  defp render_ship(_), do: ""

  defp render_row(row) do
    row
    |> Enum.map(&icon(&1))
    |> Enum.join()
  end

  defp print(message) do
    IO.puts(Process.group_leader(), message)
  end

  defp speak_result({:sunk, 5}) do
    try do
      System.cmd("say", ["You sunk my battleship"])
    rescue
      _error -> :no_say_command
    end
  end

  defp speak_result(_), do: :ok
end
