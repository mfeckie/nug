defmodule NugTest do
  use ExUnit.Case
  doctest Nug

  test "Scrubs sensitive headers" do
    path = Path.join(["test", "fixtures", "scrubbed.json"])

    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://duckduckgo.com",
        recording_file: "test/fixtures/scrubbed.json"
      })

    client =
      Nug.RequestClient.new([{"authorization", "abc123"}],
        handler: Nug.RequestHandler.get_state(pid)
      )

    Tesla.get(client, "https://duckduckgo.com/?q=hello")

    Nug.RequestHandler.close(pid)

    stored = Jason.decode!(File.read!(path), keys: :atoms)

    [%{response: response}] = stored

    assert response.opts == [
             ["req_headers", [["authorization", "**SCRUBBED**"]]],
             ["req_body", nil]
           ]
  end

  test "Takes original URL to set up proxy" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://duckduckgo.com",
        recording_file: "test/fixtures/proxy.json"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response} = Tesla.get(client, "/foo/bar/baz", query: [q: "hello"], timeout: :infinity)

    assert response.status == 200

    Nug.RequestHandler.close(pid)
  end
end
