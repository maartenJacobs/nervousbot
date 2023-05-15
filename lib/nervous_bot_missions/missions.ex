defmodule NervousBotMissions.Missions do
  alias NervousBot.Contracts
  alias NervousBot.Spacetraders.Api.LiveClient

  def start_missions!() do
    config = config()

    {:ok, [contract]} = Contracts.get_active_contracts()
    [asteroid_field] = get_asteroid_fields(contract.system)

    Enum.each(config[:ships], fn ship_symbol ->
      {:ok, _child} =
        DynamicSupervisor.start_child(
          NervousBotMissions.Missions.Supervisor,
          mission_ship_child_spec(contract, asteroid_field["symbol"], ship_symbol)
        )
    end)
  end

  defp get_asteroid_fields(system) do
    {:ok, waypoints} = LiveClient.waypoints(system)
    Enum.filter(waypoints, &(&1["type"] == "ASTEROID_FIELD"))
  end

  defp mission_ship_child_spec(%Contracts.Contract{} = contract, asteroid_waypoint, ship_symbol) do
    child_id =
      ("bot_" <> (ship_symbol |> String.downcase() |> String.replace("-", "_")))
      |> String.to_atom()

    {NervousBotMissions.Mining,
     [
       id: child_id,
       name: {:via, Registry, {NervousBotMissions.Mining.Registry, ship_symbol}},
       ship: ship_symbol,
       contract: contract,
       asteroid_waypoint: asteroid_waypoint
     ]}
  end

  def config(), do: Application.get_env(:nervous_bot, :missions)
end
