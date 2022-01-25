defmodule TictactoeWeb.Game.Index do
  use TictactoeWeb, :live_view

  require Logger

  # alias Tictactoe.Game
  alias Tictactoe.Lobby
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, %{
       status: nil
     })}
  end

  def handle_event("start", _, socket) do
    Lobby.join_lobby(self())
    {:noreply, assign(socket, %{status: :looking})}
  end

  def handle_event("play", %{"pos" => pos}, socket) when socket.assigns.status == :playing do
    PubSub.broadcast(Tictactoe.PubSub, socket.assigns.game_id, {:play, pos, socket.assigns.type})
    {:noreply, socket}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  def handle_info({:game_ready, game_id, type, turn}, socket) do
    PubSub.subscribe(Tictactoe.PubSub, game_id)

    {:noreply,
     assign(socket, %{
       game_id: game_id,
       status: :playing,
       type: type,
       turn: turn,
       game: [:e, :e, :e, :e, :e, :e, :e, :e, :e]
     })}
  end

  def handle_info({:gameover, game, type}, socket) do
    {:noreply,
     assign(socket, %{
       status: :finished,
       game: game,
       winner: type
     })}
  end


  def handle_info({:draw, game}, socket) do
    {:noreply,
    assign(socket, %{
      status: :finished,
      game: game,
      winner: :draw
    })}
  end


  def handle_info({:game_update, game, turn}, socket) do
    {:noreply, assign(socket, %{game: game, turn: turn})}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def terminate(_reason, _socket) do
    Lobby.leave_lobby(self())
  end

  def square(squares, pos) do
    Enum.at(squares, pos)
  end

end
