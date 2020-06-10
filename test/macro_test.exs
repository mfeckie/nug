defmodule MacroTestClient do
  def setup(url) do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, url}
      ],
      {Tesla.Adapter.Gun, timeout: 30_000}
    )
  end
end

defmodule MacroTest do
  use ExUnit.Case, async: true
  use Nug, upstream_url: "https://postman-echo.com", client_builder: &MacroTestClient.setup/1

  test "uses builder" do
    with_proxy("with_macro.fixture") do
      {:ok, response} = Tesla.get(client, "get")

      assert response.status == 200
    end
  end
end
