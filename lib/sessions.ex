defmodule Erlay.Sessions do
  def register(table, id, address) do
    :ets.insert(table, {id, address})
  end

  def address_of(table, id) do
    case :ets.lookup(table, id) do
      [{_, address}] -> address
      [] -> nil
    end
  end
end
