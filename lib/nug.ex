defmodule Nug do
  defmacro __using__(_opts) do
    quote do
      import Nug
    end
  end

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
