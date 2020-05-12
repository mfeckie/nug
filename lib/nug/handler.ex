defmodule Nug.Handler do
  @enforce_keys [:matchers, :upstream_base_url, :request_filename]
  defstruct [:port, :socket, :ref, :matchers, :upstream_base_url, :listen_ip, :request_filename]

  @type t :: %__MODULE__{
    port: integer(),
    socket: port(),
    ref: reference(),
    matchers: list(%Nug.Matcher{}),
    upstream_base_url: String.t(),
    listen_ip: tuple(),
    request_filename: String.t()
  }
end
