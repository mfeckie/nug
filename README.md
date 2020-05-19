# Nug

## Installation

The package can be installed by adding `nug` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nug, "~> 0.2}
  ]
end
```

Documentation [here](https://hexdocs.pm/nug).

## Disclaimer

This package is a work in progress.  If you choose to use it, I am unable to provide support, though I'm happy to look at an issues that may be filed.

## Usage

The simplest way to use Nug is via the `with_proxy` macro.  It takes the URL of the server you wish to proxy to and a filename where you'd like to record the response.

A variable `address` will be created which you can use at the base URL for your client.

```elixir
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

If you want to see additional ways in which the library can be used, please refer to the test suite.