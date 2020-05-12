defmodule NugTest do
  use ExUnit.Case
  doctest Nug

  test "Can fetch a file" do
    path = Path.join(["test", "fixtures", "test.json"])

    File.rm(path)

    client = Nug.RequestClient.new(filename: "test.json")

    Tesla.get(client, "https://duckduckgo.com/?q=hello")

    assert File.stat!(path)

    File.rm(path)
  end

  test "Scrubs sensitive headers" do
    path = Path.join(["test", "fixtures", "scrubbed.json"])

    client = Nug.RequestClient.new([{"authorization", "abc123"}], filename: "scrubbed.json")

    Tesla.get(client, "https://duckduckgo.com/?q=hello")

    stored = Jason.decode!(File.read!(path), keys: :atoms)

    assert stored.opts == [
             ["req_headers", [["authorization", "**SCRUBBED**"]]],
             ["req_body", nil]
           ]
  end

  test "Takes original URL to set up proxy" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        matchers: [],
        upstream_base_url: "https://duckduckgo.com",
        request_filename: "test.json"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response} = Tesla.get(client, "/foo/bar/baz", [query: [q: "hello"]])

    assert response.status == 200
  end
end
