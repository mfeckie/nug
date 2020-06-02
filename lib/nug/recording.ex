defmodule Nug.Recording do
  @derive Jason.Encoder
  defstruct [:request, :response]

  @type t :: %__MODULE__{
          request: %Plug.Conn{},
          response: %Tesla.Env{}
        }

  def find(_env, %Nug.Handler{recordings: []}) do
    nil
  end

  def find(%Tesla.Env{url: url, method: method}, %Nug.Handler{recordings: recordings} = _handler) do
    found =
      Enum.find(recordings, fn %Nug.Recording{response: response} ->
        response.url == url
        && response.method == method
      end)

    case found do
      nil -> nil
      %{response: response} -> {:ok, response}
    end
  end

  def add(%Tesla.Env{} = env, %Nug.Handler{} = handler) do
    scrub_fields(env)
    |> Nug.RequestHandler.add_recording(handler.pid)
  end

  def save(%Nug.Handler{} = handler) do
    encoded = :erlang.term_to_binary(handler.recordings)
    File.write(handler.recording_file, encoded)
  end

  def scrub_fields(%Tesla.Env{} = env) do
    scrubbed = Keyword.update(env.opts, :req_headers, [], &scrub_list/1)
    Map.put(env, :opts, scrubbed)
  end

  def scrub_list(list) do
    Enum.map(list, fn {key, _value} = pair ->
      case String.match?(key, ~r/authorization/) do
        true -> {key, "**SCRUBBED**"}
        false -> pair
      end
    end)
  end
end
