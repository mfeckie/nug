# TODO -> Move to own file
require Protocol
Protocol.derive(Jason.Encoder, Tesla.Env, except: [:__client__])

defimpl Jason.Encoder, for: Tuple do
  def encode(data, options) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> Jason.Encoder.List.encode(options)
  end
end

# TODO -> Move to own file
defmodule Nug.RequestClient do
  def new(headers \\ [], intercept_options)
      when is_list(intercept_options) do
    middleware = [
      Tesla.Middleware.Logger,
      Tesla.Middleware.Compression,
      {Tesla.Middleware.Headers, headers},
      {Nug.RequestInterceptor, intercept_options},
      Tesla.Middleware.KeepRequest
    ]

    Tesla.client(middleware, Tesla.Adapter.Mint)
  end
end

# TODO -> Move to own file
defmodule Nug.RequestInterceptor do
  @behaviour Tesla.Middleware
  alias Nug.Recording

  def call(env, next, intercept_options) do
    handler = Keyword.fetch!(intercept_options, :handler)

    case Recording.find(env, handler) do
      {:ok, response} -> file_to_tesla(response)
      nil -> run_and_store(env, next, handler)
    end
  end

  def run_and_store(env, next, handler) do
    with {:ok, response} <- Tesla.run(env, next),
         :ok <- Nug.Recording.add(response, handler) do
      {:ok, response}
    end
  end

  def file_to_tesla(json) do
    with normalized <- normalize(json),
         struct <- struct(Tesla.Env, normalized) do
      Tesla.run(struct, [])
    end
  end

  def normalize(raw_env) do
    Map.update(raw_env, :headers, [], fn list ->
      Enum.map(list, fn [key, value] -> {key, value} end)
    end)
  end
end
