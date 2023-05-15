defmodule NervousBot.Contracts do
  alias NervousBot.Contracts.Contract
  alias NervousBot.Spacetraders.Api.LiveClient

  def get_active_contracts() do
    {:ok, contracts} = LiveClient.contracts()

    contracts
    |> Enum.filter(& &1["accepted"])
    |> Enum.reject(& &1["fulfilled"])
    |> case do
      [] -> {:error, :no_active_contracts}
      contracts -> {:ok, contracts |> Enum.map(&parse_contract/1)}
    end
  end

  defp parse_contract(contract_data) do
    %{"terms" => %{"deliver" => [delivery_terms]}} = contract_data

    %Contract{
      id: contract_data["id"],
      system: waypoint_system(delivery_terms["destinationSymbol"]),
      waypoint: delivery_terms["destinationSymbol"],
      ore: delivery_terms["tradeSymbol"]
    }
  end

  defp waypoint_system(waypoint) do
    String.split(waypoint, "-", parts: 3)
    |> Enum.take(2)
    |> Enum.join("-")
  end
end
