defmodule Nug.RequestClient do
  def new(headers \\ [], intercept_options)
      when is_list(intercept_options) do
    middleware = [
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers, headers},
      {Nug.RequestInterceptor, intercept_options},
      Tesla.Middleware.KeepRequest
    ]

    Tesla.client(middleware, {Tesla.Adapter.Gun, timeout: 30_000})
  end
end
