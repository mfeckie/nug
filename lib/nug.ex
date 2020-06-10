defmodule Nug do
  @moduledoc """
  Provides a macro for using Nug in tests
  """
  defmacro __using__([]) do
    quote do
      import Nug
    end
  end

  defmacro __using__(opts) do
    quote do
      @upstream_url Keyword.fetch!(unquote(opts), :upstream_url)
      @client_builder Keyword.fetch!(unquote(opts), :client_builder)
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
        client = TestClient.new(address)

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

  defmacro with_proxy(builder, upstream_url, recording_file, test_body) do
    test_file_name = "test/fixtures/#{recording_file}"

    quote do
      {:ok, pid} =
        Nug.HandlerSupervisor.start_child(%Nug.Handler{
          upstream_url: unquote(upstream_url),
          recording_file: unquote(test_file_name)
        })

      var!(client) = unquote(builder).(Nug.RequestHandler.listen_address(pid))
      # Avoid unused variable warnings as the client is just a convenience
      _ = var!(client)

      try do
        unquote(test_body)
      after
        Nug.RequestHandler.close(pid)
      end
    end
  end

  defmacro with_proxy(recording_file, do: test_body) do
    test_file_name = "test/fixtures/#{recording_file}"
    upstream_url = Module.get_attribute(__CALLER__.module, :upstream_url)
    client_builder = Module.get_attribute(__CALLER__.module, :client_builder)

    quote do
      {:ok, pid} =
        Nug.HandlerSupervisor.start_child(%Nug.Handler{
          upstream_url: unquote(upstream_url),
          recording_file: unquote(test_file_name)
        })

      var!(client) = unquote(client_builder).(Nug.RequestHandler.listen_address(pid))
      # Avoid unused variable warnings as the client is just a convenience
      _ = var!(client)

      try do
        unquote(test_body)
      after
        Nug.RequestHandler.close(pid)
      end
    end
  end
end
