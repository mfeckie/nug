defmodule Mix.Tasks do
  defmodule Nug.Show do
    @shortdoc "Pretty print fixtures"
    use Mix.Task

    def run(_) do
      File.ls("test/fixtures")
      |> print_files()
    end

    def print_files({:ok, files}) do
      Enum.each(files, fn file ->
        path = Path.join(["test/fixtures", file])
        IO.puts("#{IO.ANSI.blue_background()<>IO.ANSI.white()}Filename: #{path}#{IO.ANSI.reset()}")

        content =
          File.read!(path)
          |> :erlang.binary_to_term()

        IO.inspect(content)
      end)
    end
  end
end
