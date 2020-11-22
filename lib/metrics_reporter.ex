defmodule Erlay.MetricsReporter do
  use GenServer

  alias Erlay.Metrics

  require Logger

  @report_frequency 5
  @report_interval @report_frequency * 1000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(%{:metrics => metrics}) do
    {:ok, {_, timer}} = :timer.send_interval(@report_interval, :report)
    {:ok, %{metrics: metrics, timer: timer}}
  end

  @impl true
  def handle_info(:report, %{:metrics => metrics} = state) do
    %{
      :bytes_sent => bytes_sent,
      :bytes_received => bytes_received
    } = Metrics.get(metrics)

    sent_mbits_sec = to_mbits_per_second(bytes_sent)
    received_mbits_sec = to_mbits_per_second(bytes_received)
    metrics = Metrics.clear(metrics)

    Logger.info("up #{f2b(sent_mbits_sec)} Mbps down #{f2b(received_mbits_sec)} Mbps")

    {:noreply, Map.put(state, :metrics, metrics)}
  end

  defp to_mbits(bytes) do
    bytes * 8 / 1_000_000
  end

  defp to_mbits_per_second(bytes) do
    to_mbits(bytes) / @report_frequency
  end

  defp f2b(v, decimals \\ 3) do
    :erlang.float_to_binary(v, decimals: decimals)
  end
end
