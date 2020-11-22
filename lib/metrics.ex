defmodule Erlay.Metrics do
  @bytes_sent_index 1
  @bytes_received_index 2

  def new() do
    %{:counters => :counters.new(5, [:write_concurrency])}
  end

  def add_bytes_sent(%{:counters => counters} = metrics, amount) do
    :counters.add(counters, @bytes_sent_index, amount)
    metrics
  end

  def add_bytes_received(%{:counters => counters} = metrics, amount) do
    :counters.add(counters, @bytes_received_index, amount)
    metrics
  end

  def clear(%{:counters => counters} = metrics) do
    :counters.put(counters, @bytes_sent_index, 0)
    :counters.put(counters, @bytes_received_index, 0)
    metrics
  end

  def get(%{:counters => counters}) do
    bytes_sent = :counters.get(counters, @bytes_sent_index)
    bytes_received = :counters.get(counters, @bytes_received_index)

    %{
      :bytes_sent => bytes_sent,
      :bytes_received => bytes_received,
    }
  end
end
