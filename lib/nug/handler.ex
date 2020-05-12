defmodule Nug.Handler do
  @enforce_keys [:upstream_url, :recording_file]
  defstruct [
    :port,
    :pid,
    :socket,
    :ref,
    :upstream_url,
    :listen_ip,
    :recording_file,
    recordings: []
  ]

  @type t :: %__MODULE__{
          pid: pid(),
          port: integer(),
          socket: port(),
          ref: reference(),
          upstream_url: String.t(),
          listen_ip: tuple(),
          recording_file: String.t(),
          recordings: [%Nug.Recording{}]
        }
end
