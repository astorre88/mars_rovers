defmodule MarsRovers.SpaceShip do
  use GenServer

  # API

  def start_link(objectives) do
    GenServer.start_link(__MODULE__, objectives, name: __MODULE__)
  end

  def land_rover(position) do
    GenServer.call(__MODULE__, {:land_rover, position})
  end

  def step(rover) do
    GenServer.call(__MODULE__, {:step, rover})
  end

  def on_board_rovers do
    GenServer.call(__MODULE__, :on_board_rovers)
  end

  def on_plateau_rovers do
    GenServer.call(__MODULE__, :on_plateau_rovers)
  end

  # Callbacks

  def init(objectives) do
    objectives = ObjectivesParser.parse_to_map(objectives)
    {:ok, objectives}
  end

  def handle_call({:land_rover, position}, _from, objectives) do
    [rover | rest_rovers] = objectives.on_board
    [nx, ny, _] = rover.position
    case in_plateau?(nx, ny, objectives.plateau) do
      true ->
        on_board = rest_rovers
        on_plateau = [rover | objectives.on_plateau]
        {:reply, rover, %{objectives | on_board: on_board, on_plateau: on_plateau}}
      false ->
        {:reply, {:error, :cant_land}, objectives}
    end
  end

  def handle_call({:step, rover}, _from, objectives) do
    case rover do
      {:error, message} ->
        {:reply, message, objectives}
      %{position: position, commands: [command | commands]} ->
        move_rover(rover, position, command, commands, objectives)
    end
  end

  def handle_call(:on_board_rovers, _from, objectives) do
    {:reply, objectives.on_board, objectives}
  end

  def handle_call(:on_plateau_rovers, _from, objectives) do
    {:reply, objectives.on_plateau, objectives}
  end

  defp move_rover(rover, position, command, commands, objectives) do
    case new_position(position, command, objectives) do
      {:ok, position} ->
        rover = %{commands: commands, position: position}
        objectives = update_objectives(objectives, rover)
        {:reply, rover, objectives}
      {:error, message} ->
        rover = {:error, message}
        objectives = update_objectives(objectives, rover)
        {:reply, rover, objectives}
    end
  end

  defp update_objectives(objectives, data) do
    [rest | _] = Enum.reverse(objectives.on_plateau)
    %{objectives | on_plateau: [rest, data]}
  end

  defp new_position(old_position, command, objectives) do
    [x, y, current_direction] = old_position
    case command do
      "M" -> move(x, y, current_direction, objectives)
      _ -> {:ok, [x, y, change_direction(current_direction, command)]}
    end
  end

  defp move(x, y, direction, objectives) do
    [nx, ny] = case direction do
      "N" -> [x, y + 1]
      "E" -> [x + 1, y]
      "S" -> [x, y - 1]
      "W" -> [x - 1, y]
    end

    case in_plateau?(nx, ny, objectives.plateau) do
      true -> {:ok, change_position(x, y, nx, ny, direction, objectives)}
      _ -> {:error, {:out_of_plateau, {nx, ny, direction}}}
    end
  end

  defp in_plateau?(nx, ny, plateau) do
    case plateau do
      [width, height] when nx in 0..width and ny in 0..height ->
        true
      _ ->
        false
    end
  end

  defp change_position(x, y, nx, ny, direction, objectives) do
    case occupied?(nx, ny, objectives) do
      true -> [x, y, direction]
      _ -> [nx, ny, direction]
    end
  end

  defp occupied?(nx, ny, %{on_plateau: on_plateau} = objectives) do
    on_plateau
    |> Enum.filter(&is_map/1)
    |> Enum.any?(fn rover ->
      [rx, ry, _] = rover.position
      rx == nx and ry == ny
    end)
  end

  defp change_direction(current_direction, "L") do
    case current_direction do
      "N" -> "W"
      "E" -> "N"
      "S" -> "E"
      "W" -> "S"
    end
  end

  defp change_direction(current_direction, "R") do
    case current_direction do
      "N" -> "E"
      "E" -> "S"
      "S" -> "W"
      "W" -> "N"
    end
  end

  defp change_direction(current_direction, _) do
    {:error, "Unknown direction"}
  end
end
