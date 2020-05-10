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
end
