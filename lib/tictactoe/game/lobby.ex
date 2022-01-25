defmodule Tictactoe.Lobby do
  use GenServer

  alias Tictactoe.Game

  @lobby __MODULE__

  def start_link(default) do
    GenServer.start_link(@lobby, default, name: @lobby)
  end

  def init(state \\ []) do
    {:ok, state}
  end

  def handle_cast({:add, player}, state) do
    {:noreply, state ++ [player]}
  end

  def handle_cast({:leave, player}, state) do
    {:noreply, Enum.reject(state, &(&1 == player))}
  end

  def handle_call(:lobby, _from, state) do
    {:reply, state, state}
  end

  def leave_lobby(pid) do
    GenServer.cast(@lobby, {:leave, pid})
  end

  def join_lobby(pid) do
    players = GenServer.call(@lobby, :lobby)
    if length(players) > 0 do
      Game.create_game(pid, List.first(players))
      leave_lobby(List.first(players))
    else
      GenServer.cast(@lobby, {:add, pid})
    end
  end

end
