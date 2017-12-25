defmodule ObjectivesParser do
  def parse_to_map(objectives) do
    parsed_objectives = objectives
                        |> String.split("\n", trim: true)
                        |> Enum.map(&(String.split(&1)))
    [[plateau_width, plateau_height] | rovers] = parsed_objectives
    rovers = Enum.chunk_every(rovers, 2)
              |> Enum.map(fn rover ->
                [[x, y, d], [commands]] = rover
                %{
                  position: [
                    String.to_integer(x),
                    String.to_integer(y),
                    d],
                  commands: String.codepoints(commands)
                }
              end)
    %{
      plateau: [
        String.to_integer(plateau_width),
        String.to_integer(plateau_height)
      ],
      on_board: rovers,
      on_plateau: []
    }
  end
end
