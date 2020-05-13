defmodule Nug.RequestHandler do
  use GenServer, restart: :transient

  def start_link(%Nug.Handler{} = opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(%Nug.Handler{} = opts) do
    case get_port() do
      {:ok, port} ->
        state = do_up(make_ref(), port, opts)
        {:ok, state}

      err ->
        err
    end
  end

  def get_state(pid) do
    GenServer.call(pid, :config)
  end

  def listen_address(pid) do
    GenServer.call(pid, :listen_address)
  end

  def close(pid) do
    GenServer.call(pid, :close)
  end

  def add_recording(%Tesla.Env{} = env, pid) do
    GenServer.call(pid, {:add_recording, env})
  end

  defp do_up(ref, port, handler) do
    {:ok, socket} = :ranch_tcp.listen(so_reuseport() ++ [ip: listen_ip(), port: port])

    handler =
      struct(handler, %{
        pid: self(),
        port: port,
        ref: make_ref(),
        socket: socket,
        listen_ip: listen_ip()
      })
      |> add_file()

    plug_options = [handler: handler, timeout: 10_000]

    cowboy_options = [
      ref: ref,
      port: port,
      transport_options: [num_acceptors: 5, socket: socket]
    ]

    {:ok, _pid} = Plug.Cowboy.http(Nug.RequestServer, plug_options, cowboy_options)

    handler
  end

  def add_file(%Nug.Handler{} = handler) do
    case File.read(handler.recording_file) do
      {:ok, file} ->
        recordings =
          Jason.decode!(file, keys: :atoms)
          |> Enum.map(&struct(Nug.Recording, &1))

        Map.put(handler, :recordings, recordings)

      _ ->
        handler
    end
  end

  defp get_port(port \\ 0) do
    case :ranch_tcp.listen(so_reuseport() ++ [ip: listen_ip(), port: port]) do
      {:ok, socket} ->
        {:ok, port} = :inet.port(socket)
        :erlang.port_close(socket)
        {:ok, port}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  # Ref -> https://github.com/PSPDFKit-labs/bypass/blob/master/lib/bypass/instance.ex#L373-L402
  defp so_reuseport() do
    case :os.type() do
      {:unix, :linux} -> [{:raw, 1, 15, <<1::32-native>>}]
      {:unix, :darwin} -> [{:raw, 65535, 512, <<1::32-native>>}]
      _ -> []
    end
  end

  defp listen_ip() do
    Application.get_env(:nug, :ip, {127, 0, 0, 1})
  end

  def handle_call(:config, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:listen_address, _from, %Nug.Handler{listen_ip: ip, port: port} = state) do
    string_ip = Tuple.to_list(ip) |> Enum.join(".")
    listen_address = string_ip <> ":#{port}"
    {:reply, listen_address, state}
  end

  def handle_call({:add_recording, env}, _from, state) do
    new_state =
      Map.update(state, :recordings, [], fn recordings ->
        [%Nug.Recording{response: env} | recordings]
      end)

    Process.put(:updated_recordings, true)
    {:reply, :ok, new_state}
  end

  def handle_call(:close, _from, state) do
    if Process.get(:updated_recordings) do
      Nug.Recording.save(state)
    end

    {:stop, :normal, :ok, []}
  end
end
