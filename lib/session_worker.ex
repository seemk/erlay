defmodule Erlay.SessionWorker do
  use GenServer

  alias Erlay.Sessions

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(%{:address => address, sessions: sessions}) do
    Process.send_after(self(), :start, 0)
    {:ok, %{address: address, sessions: sessions}}
  end

  @impl true
  def handle_info(:start, %{address: address, sessions: sessions} = state) do
    client_socket = open_socket(address, 3478)
    peer_socket = open_socket(address, 3479)

    spawn_link(__MODULE__, :client_loop, [client_socket, self(), sessions])
    spawn_link(__MODULE__, :peer_loop, [client_socket, peer_socket, self(), sessions])
    {:noreply, state}
  end

  def client_loop(socket, parent, sessions) do
    {:ok, {from, <<id::little-integer-size(64), _rest::binary>>}} =
      :socket.recvfrom(socket, 32, [], :infinity)

    Sessions.register(sessions, id, from)
    client_loop(socket, parent, sessions)
  end

  def peer_loop(client_socket, peer_socket, parent, sessions) do
    {:ok, {_from, <<id::little-integer-size(64), _rest::binary>> = packet}} =
      :socket.recvfrom(peer_socket, 1024, [], :infinity)

    to = Sessions.address_of(sessions, id)

    if to do
      :socket.sendto(client_socket, packet, to)
    end

    peer_loop(client_socket, peer_socket, parent, sessions)
  end

  def open_socket(address, port) do
    {:ok, socket} = :socket.open(:inet, :dgram, :udp)
    :ok = :socket.setopt(socket, :socket, :reuseaddr, true)
    :ok = :socket.setopt(socket, :socket, :reuseport, true)
    {:ok, _port} = :socket.bind(socket, %{family: :inet, port: port, addr: address})
    socket
  end
end
