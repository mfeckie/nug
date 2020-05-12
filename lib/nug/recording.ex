defmodule Nug.Recording do
  @derive Jason.Encoder
  defstruct [:request, :response]

  @type t :: %__MODULE__{
          request: %Plug.Conn{},
          response: %Tesla.Env{}
        }

  def find(env, %Nug.Handler{recordings: []}) do
    nil
  end

  def find(env, %Nug.Handler{recordings: recordings}) do
    Enum.find(recordings, fn %Nug.Recording{response: response} ->

    end) || nil
  end

  def add(env = %Tesla.Env{}, %Nug.Handler{} = handler) do
    scrub_fields(env)
    |> Nug.RequestHandler.add_recording(handler.pid)
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
