defmodule Nug.HandlerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end

  def start_child(%Nug.Handler{} = options) do
    child_spec = {Nug.RequestHandler, options}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

end
