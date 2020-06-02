defmodule NugTest do
  use ExUnit.Case, async: true
  doctest Nug

  test "Scrubs sensitive headers" do
    path = Path.join(["test", "fixtures", "scrubbed.fixture"])

    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://duckduckgo.com",
        recording_file: "test/fixtures/scrubbed.fixture"
      })

    client =
      Nug.RequestClient.new([{"authorization", "abc123"}],
        handler: Nug.RequestHandler.get_state(pid)
      )

    Tesla.get(client, "https://duckduckgo.com/?q=hello")

    Nug.RequestHandler.close(pid)

    stored = :erlang.binary_to_term(File.read!(path))

    [%{response: response}] = stored

    assert response.opts == [{:req_headers, [{"authorization", "**SCRUBBED**"}]}, {:req_body, nil}]
  end

  test "Takes original URL to set up proxy" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://duckduckgo.com",
        recording_file: "test/fixtures/proxy.fixture"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response} = Tesla.get(client, "/foo/bar/baz", query: [q: "hello"])

    assert response.status == 200

    Nug.RequestHandler.close(pid)
  end

  test "Multiple requests" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://duckduckgo.com",
        recording_file: "test/fixtures/multiple.fixture"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response1} = Tesla.get(client, "/", query: [q: "hello"])
    {:ok, response2} = Tesla.get(client, "/", query: [q: "goodbye"])

    assert response1.status == 200
    assert response1.query == [q: "hello"]

    assert response2.status == 200
    assert response2.query == [q: "goodbye"]

    Nug.RequestHandler.close(pid)
  end

  test "Multiple requests different method" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://postman-echo.com",
        recording_file: "test/fixtures/multiple-request-different-method.fixture"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response1} = Tesla.get(client, "/get")
    {:ok, response2} = Tesla.post(client, "/post", %{test: "test"})

    assert response1.status == 200

    assert response2.status == 200

    Nug.RequestHandler.close(pid)
  end

  test "POST with body" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://postman-echo.com/post",
        recording_file: "test/fixtures/post-with-body.fixture"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response} = Tesla.post(client, "/", %{test: "test"})

    assert response.status == 200

    Nug.RequestHandler.close(pid)
  end

  test "PUT with body" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://postman-echo.com/put",
        recording_file: "test/fixtures/put-with-body.fixture"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response} = Tesla.put(client, "/", %{test: "PUT"})

    assert response.status == 200

    Nug.RequestHandler.close(pid)
  end

  test "PATCH with body" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://postman-echo.com/patch",
        recording_file: "test/fixtures/patch-with-body.fixture"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response} = Tesla.patch(client, "/", %{test: "PATCH"})

    assert response.status == 200

    Nug.RequestHandler.close(pid)
  end

  test "DELETE" do
    {:ok, pid} =
      Nug.HandlerSupervisor.start_child(%Nug.Handler{
        upstream_url: "https://postman-echo.com/delete",
        recording_file: "test/fixtures/delete.fixture"
      })

    address = Nug.RequestHandler.listen_address(pid)

    client = TestClient.new("http://#{address}")

    {:ok, response} = Tesla.delete(client, "/")

    assert response.status == 200

    Nug.RequestHandler.close(pid)
  end
end
