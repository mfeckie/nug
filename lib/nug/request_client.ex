require Protocol
Protocol.derive(Jason.Encoder, Tesla.Env, except: [:__client__])

defimpl Jason.Encoder, for: Tuple do
  def encode(data, options) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> Jason.Encoder.List.encode(options)
  end
end

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

defmodule Nug.RequestInterceptor do
  @behaviour Tesla.Middleware

  def call(env, next, intercept_options) do
    filename = Keyword.fetch!(intercept_options, :filename)

    File.mkdir_p(Path.join(["test", "fixtures"]))

    qualified_filename = Path.join(["test", "fixtures", filename])

    case File.read(qualified_filename) do
      {:ok, json} ->
        file_to_tesla(json)

      {:error, :enoent} ->
        run_and_store(env, next, intercept_options, qualified_filename)
    end
  end

  def run_and_store(env, next, _intercept_options, filename) do
    with {:ok, response} <- Tesla.run(env, next),
         {:ok, scrubbed} <- scrub_fields(response),
         {:ok, encoded} <- Jason.encode(scrubbed, pretty: true),
         :ok <- File.write(filename, encoded) do
      {:ok, response}
    end
  end

  def file_to_tesla(json) do
    with {:ok, raw} <- Jason.decode(json, keys: :atoms),
         normalized <- normalize(raw),
         struct <- struct(Tesla.Env, normalized) do
      Tesla.run(struct, [])
    end
  end

  def normalize(raw_env) do
    Map.update(raw_env, :headers, [], fn list ->
      Enum.map(list, fn [key, value] -> {key, value} end)
    end)
  end

  def scrub_fields(%Tesla.Env{} = env) do
    scrubbed = Keyword.update(env.opts, :req_headers, [], &scrub_list/1)
    {:ok, Map.put(env, :opts, scrubbed)}
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
