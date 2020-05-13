defmodule TestClient do
  def new(url) do
    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware, Tesla.Adapter.Mint)
  end
end

ExUnit.start()
