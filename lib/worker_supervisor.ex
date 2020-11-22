defmodule Erlay.WorkerSupervisor do
  use Supervisor

  alias Erlay.SessionWorker
  alias Erlay.Metrics
  alias Erlay.MetricsReporter

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    {:ok, address} =
      address_from_env()
      |> String.to_charlist()
      |> :inet.parse_address()

    metrics = Metrics.new()
    sessions = :ets.new(:sessions_registry, [:set, :public, {:read_concurrency, true}])

    args = %{address: address, sessions: sessions, metrics: metrics}

    reporter = %{
      start: {MetricsReporter, :start_link, [args]},
      id: MetricsReporter
    }

    workers =
      Enum.map(1..System.schedulers_online(), fn id ->
        %{start: {SessionWorker, :start_link, [args]}, id: {SessionWorker, id}}
      end)

    children = [reporter | workers]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp address_from_env() do
    Application.get_env(:erlay, :address) || "127.0.0.1"
  end
end
