defmodule Nug.SetupExampleTest do
  use ExUnit.Case, async: true
  use Nug

  test "With macro" do
    with_proxy("https://duckduckgo.com", "test/fixtures/with-macro.fixture") do
      client = TestClient.new("http://#{address}")

      {:ok, response} = Tesla.get(client, "/", query: [q: "hello"])

      assert response.status == 200
    end
  end
end
