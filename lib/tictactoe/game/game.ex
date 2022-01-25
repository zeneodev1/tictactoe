defmodule Tictactoe.Game do
  use GenServer, restart: :transient

  @game __MODULE__

  alias Phoenix.PubSub

  def start_link(default) do
    GenServer.start_link(@game, default, name: {:global, default.game_id})
  end

  def init(state) do
    PubSub.subscribe(Tictactoe.PubSub, state.game_id)
    {:ok, state}
  end

  def handle_info({:play, pos, type}, state) when type == state.turn do
    case play(state.squares, pos, type) do
      :already_played ->
        {:noreply, state}

      squares ->
        case check_win(squares, pos, type) do
          true ->
            PubSub.broadcast(Tictactoe.PubSub, state.game_id, {:gameover, squares, type})
            {:stop, :normal, state}
            false ->
            case check_draw(squares) do
              true ->
                PubSub.broadcast(Tictactoe.PubSub, state.game_id, {:draw, squares})
                {:stop, :normal, state}
              false ->
                turn = opposite_turn(state.turn)
                PubSub.broadcast(Tictactoe.PubSub, state.game_id, {:game_update, squares, turn})
                {:noreply, %{state | squares: squares, turn: turn}}
              end
        end
    end
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp check_draw(squares) do
    squares
    |> Enum.all?(&(&1 != :e))
  end

  defp check_win(squares, pos, type) do
    pos = String.to_integer(pos)

    check_horizontal(squares, pos, type) || check_vertical(squares, pos, type) ||
      check_diagonals(squares, type)
  end

  def check_horizontal(squares, pos, type) do
    Enum.slice(squares, div(pos, 3) * 3, 3)
    |> Enum.all?(&(&1 == type))
  end

  def check_vertical(squares, pos, type) do
    0..2
    |> Enum.reduce([], fn elem, acc ->
      acc ++ [Enum.at(squares, rem(pos, 3) + 3 * elem)]
    end)
    |> Enum.all?(&(&1 == type))
  end

  def check_diagonals(squares, type) do
    [Enum.at(squares, 0), Enum.at(squares, 4), Enum.at(squares, 8)] |> Enum.all?(&(&1 == type)) ||
      [Enum.at(squares, 2), Enum.at(squares, 4), Enum.at(squares, 6)] |> Enum.all?(&(&1 == type))
  end

  defp play(squares, pos, type) do
    pos = String.to_integer(pos)

    case Enum.at(squares, pos, :e) do
      :e ->
        List.replace_at(squares, pos, type)

      _ ->
        :already_played
    end
  end

  defp generate_game_token() do
    :crypto.strong_rand_bytes(10)
  end

  defp opposite_turn(:x), do: :o

  defp opposite_turn(:o), do: :x

  def create_game(pid1, pid2) do
    token = generate_game_token()

    DynamicSupervisor.start_child(
      Tictactoe.GamesSupervisor,
      {@game, %{squares: [:e, :e, :e, :e, :e, :e, :e, :e, :e], game_id: token, turn: :x}}
    )

    send(pid1, {:game_ready, token, :x, :x})
    send(pid2, {:game_ready, token, :o, :x})
  end
end
