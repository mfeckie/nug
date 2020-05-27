defmodule Nug do
  @moduledoc """
  Provides a macro for using Nug in tests
  """
  defmacro __using__(_opts) do
    quote do
      import Nug
    end
  end

  @doc ~S"""
  `with_proxy` is convenience macro that will handle setup and teardown of your proxy server.

  # Usage

  The `with_proxy` macro starts the proxy server and provides you with a variable in the block called `address`
  this is the server address that will be listening for requests made in the block
  ```
  defmodule TestCase do
    use ExUnit.Case, async: true
    use Nug

    test "get response from API" do
      with_proxy("https://www.example.com", "test/fixtures/example.fixture") do
        # address is a variable that is created by the macro
        client = TestClient.new("http://#{address}")

        {:ok, response} = Tesla.get(client, "/", query: [q: "hello"])

        assert response.status == 200
      end
    end
  end
  ```

  """
  defmacro with_proxy(upstream_url, recording_file, test_body) do
    quote do
      {:ok, pid} =
        Nug.HandlerSupervisor.start_child(%Nug.Handler{
          upstream_url: unquote(upstream_url),
          recording_file: unquote(recording_file)
        })

      var!(address) = Nug.RequestHandler.listen_address(pid)

      try do
        unquote(test_body)
      after
        Nug.RequestHandler.close(pid)
      end
    end
  end
end
