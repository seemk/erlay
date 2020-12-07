defmodule Erlay.SessionWorker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(%{:address => address, sessions: sessions, metrics: metrics}) do
    Process.send_after(self(), :start, 0)
    {:ok, %{address: address, sessions: sessions, metrics: metrics}}
  end

  @impl true
  def handle_info(
        {:udp, socket, address, port, packet},
        %{client_socket: client_socket, peer_socket: peer_socket} = state
      ) do
    case socket do
      ^peer_socket ->
        relay_data(packet, state)

      ^client_socket ->
        <<id::little-integer-size(64), _rest::binary>> = packet
        Erlay.Sessions.register(state[:sessions], id, {address, port})
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:start, %{address: address} = state) do
    opts = [
      :binary,
      :inet,
      {:ip, address},
      {:active, true},
      {:reuseaddr, true},
      {:buffer, 1500},
      {:recbuf, 32 * 1024 * 1024},
      {:sndbuf, 32 * 1024 * 1024},
      {:read_packets, 1024},
      {:raw, 0x0001, 0x000F, <<1::native-integer-32>>}
    ]

    {:ok, client_socket} = :gen_udp.open(3478, opts)
    {:ok, peer_socket} = :gen_udp.open(3479, opts)

    {:noreply, Map.merge(state, %{client_socket: client_socket, peer_socket: peer_socket})}
  end

  def relay_data(
        packet,
        %{client_socket: client_socket, sessions: sessions, metrics: metrics}
      ) do
    <<id::little-integer-size(64), _rest::binary>> = packet

    packet_size = byte_size(packet)
    Erlay.Metrics.add_bytes_received(metrics, packet_size)

    case Erlay.Sessions.address_of(sessions, id) do
      {addr, port} ->
        :gen_udp.send(client_socket, addr, port, packet)
        Erlay.Metrics.add_bytes_sent(metrics, packet_size)

      _ ->
        nil
    end
  end
end
