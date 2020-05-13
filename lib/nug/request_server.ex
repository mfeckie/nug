defmodule Nug.RequestServer do
  def init(options), do: options

  def call(
        conn,
        options
      ) do
    handler = Keyword.fetch!(options, :handler)
    do_request(conn, handler)
  end

  def do_request(%Plug.Conn{method: method} = conn, %Nug.Handler{} = handler) do
    client = Nug.RequestClient.new(handler: handler, conn: conn)

    url = build_url(conn, handler.upstream_url)

    case method do
      "GET" ->
        do_get(client, conn, url)
      "POST" ->
        do_post(client, conn, url)
    end
  end

  def do_get(client, conn, url) do
    case Tesla.get(client, url) do
      {:ok, env} ->
        env_to_conn(env, conn)
    end
  end

  def do_post(client, conn, url) do
    {:ok, body, _} = Plug.Conn.read_body(conn)
    case Tesla.post(client, url, body) do
      {:ok, env} ->
        env_to_conn(env, conn)
    end
  end

  defp env_to_conn(env, conn) do
    conn
    |> Map.put(:resp_headers, env.headers)
    |> Plug.Conn.resp(env.status, env.body)
    |> Plug.Conn.send_resp()
  end

  defp build_url(%Plug.Conn{request_path: request_path, query_string: query_string}, base_url) do
    case query_string do
      "" -> "#{base_url}#{request_path}"
      query -> "#{base_url}#{request_path}?#{query}"
    end
  end
end
