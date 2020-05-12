defmodule Nug.Handler do
  @enforce_keys [:matchers]
  defstruct [:port, :socket, :ref, :matchers, :upstream_base_url]

  @type t :: %__MODULE__{
    port: integer(),
    socket: port(),
    ref: reference(),
    matchers: list(%Nug.Matcher{}),
    upstream_base_url: String.t()
  }
end
