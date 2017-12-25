defmodule MarsRovers do
  use Application

  def start(_type, _args) do
    filename = "lib/mission_objectives.txt"
    case File.read(filename) do
      {:ok, objectives} ->
        MarsRovers.Supervisor.start_link(objectives)
      {:error, _} ->
        {:error, "File open error: #{filename}"}
    end
  end

  def start_mission do
    MarsRovers.SpaceShip.on_board_rovers()
    |> Enum.map(fn position ->
      Task.async(fn ->
        rover = MarsRovers.SpaceShip.land_rover(position)
        move_through_commands(rover)
      end)
    end)
    |> Enum.map(fn task ->
      result = Task.await(task)
      case result do
        {:error, message} -> result
        _ -> result.position |> Enum.join(" ")
      end
    end)
    |> Enum.each(&IO.inspect/1)
  end

  defp move_through_commands({:error, _} = rover) do
    rover
  end
  defp move_through_commands(%{commands: []} = rover) do
    rover
  end
  defp move_through_commands(rover) do
    rover = MarsRovers.SpaceShip.step(rover)
    move_through_commands(rover)
  end
end
