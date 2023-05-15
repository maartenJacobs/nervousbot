defmodule NervousBot.Fleet do
  alias NervousBot.Fleet.{Cargo, Inventory}
  alias NervousBot.Spacetraders.Api.LiveClient

  def orbit(ship_id) do
    with {:ok, _} <- LiveClient.orbit(ship_id) do
      :ok
    end
  end

  def dock(ship_id) do
    with {:ok, _} <- LiveClient.dock(ship_id) do
      :ok
    end
  end

  def parse_cargo(cargo_payload) do
    %Cargo{
      capacity: cargo_payload["capacity"],
      inventory:
        cargo_payload["inventory"]
        |> Enum.map(fn inventory ->
          %Inventory{
            description: inventory["description"],
            name: inventory["name"],
            symbol: inventory["symbol"],
            units: inventory["units"]
          }
        end),
      units: cargo_payload["units"]
    }
  end

  def get_cargo(ship_id) do
    with {:ok, cargo_payload} = LiveClient.ship_cargo(ship_id) do
      {:ok, parse_cargo(cargo_payload)}
    end
  end

  def empty_cargo?(%Cargo{} = cargo) do
    cargo.units == 0
  end

  def full_cargo?(%Cargo{} = cargo) do
    cargo.units == cargo.capacity
  end

  def get_inventory_level(cargo, item_id) do
    Enum.find(cargo.inventory, fn inventory ->
      inventory.symbol == item_id
    end)
    |> case do
      nil -> 0
      %Inventory{units: quantity} -> quantity
    end
  end
end
