defmodule Erlay do
  use Application

  @impl true
  def start(_type, _args) do
    Erlay.WorkerSupervisor.start_link(name: Erlay.WorkerSupervisor)
  end
end
