defmodule Nug.RequestInterceptor do
  @behaviour Tesla.Middleware
  alias Nug.Recording

  def call(env, next, intercept_options) do
    handler = Keyword.fetch!(intercept_options, :handler)

    case Recording.find(env, handler) do
      {:ok, response} -> Tesla.run(response, [])
      nil -> run_and_store(env, next, handler)
    end
  end

  def run_and_store(env, next, handler) do
    with {:ok, response} <- Tesla.run(env, next),
         :ok <- Nug.Recording.add(response, handler) do
      {:ok, response}
    end
  end
end
