defmodule NervousBotMissions.Mining do
  @moduledoc """
  Rookie mining mission.

  Assume:
    - ship NERV0USCL0UD-2
    - docked at the market at waypoint X1-DF55-17335A of system X1-DF55
    - contract clhgfk65n03iks60dxmw4619b at X1-DF55-20250Z
  """

  @behaviour :gen_statem

  require Logger

  alias NervousBot.{Contracts, Fleet}
  alias NervousBot.Spacetraders.Api.LiveClient

  # State

  @type t :: %__MODULE__{
          ship: String.t(),
          asteroid_waypoint: String.t(),
          contract: Contracts.Contract.t(),
          cargo: Fleet.Cargo.t() | nil
        }

  defstruct [:ship, :asteroid_waypoint, :contract, :cargo]

  # API

  def child_spec(opts) do
    %{
      id: opts[:id] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary,
      shutdown: 500,
      name: opts[:name] || nil
    }
  end

  def start_link(opts) do
    ship = Keyword.fetch!(opts, :ship)
    contract = Keyword.fetch!(opts, :contract)
    asteroid_waypoint = Keyword.fetch!(opts, :asteroid_waypoint)

    :gen_statem.start_link(
      __MODULE__,
      {ship, contract, asteroid_waypoint},
      []
    )
  end

  # Callbacks

  @impl true
  def init({ship, contract, asteroid_waypoint}) do
    actions = [{:next_event, :internal, :checking_stop}]

    {:ok, :selling,
     %__MODULE__{
       ship: ship,
       asteroid_waypoint: asteroid_waypoint,
       contract: contract,
       cargo: nil
     }, actions}
  end

  @impl true
  def callback_mode() do
    [:state_functions, :state_enter]
  end

  ## State callbacks

  def delivering(:enter, _, %__MODULE__{} = data) do
    Logger.info("Navigating to contract waypoint #{data.contract.waypoint} to deliver goods")
    arrival_in_secs = navigate(data, data.contract.waypoint)
    {:keep_state_and_data, [{:state_timeout, arrival_in_secs * 1000, :delivering}]}
  end

  def delivering(:state_timeout, _, %__MODULE__{} = data) do
    contract_ore = Fleet.get_inventory_level(data.cargo, data.contract.ore)
    Logger.info("Delivering #{contract_ore} #{data.contract.ore}")

    {:ok, _} = LiveClient.dock(data.ship)

    {:ok, response} =
      LiveClient.deliver(data.contract.id, data.ship, data.contract.ore, contract_ore)

    data = struct!(data, cargo: Fleet.parse_cargo(response["cargo"]))

    NervousBotWeb.Endpoint.broadcast("contract-delivered", data.contract.ore, %{})

    Logger.info("Navigating to asteroids waypoint #{data.asteroid_waypoint} to extract")
    arrival_in_secs = navigate(data, data.asteroid_waypoint)

    {:next_state, :selling, data, [{:state_timeout, arrival_in_secs * 1000, :selling}]}
  end

  def selling(:enter, _, _data) do
    :keep_state_and_data
  end

  def selling(:state_timeout, _, _data) do
    {:keep_state_and_data, [{:next_event, :internal, :checking_stop}]}
  end

  def selling(:internal, :checking_stop, %__MODULE__{ship: ship} = data) do
    Logger.info("Checking if ship #{ship} has contract ore")

    {:ok, _} = LiveClient.dock(data.ship)
    {:ok, _} = LiveClient.refuel(ship)

    {:ok, cargo} = Fleet.get_cargo(ship)
    data = struct!(data, cargo: cargo)

    cond do
      Fleet.empty_cargo?(data.cargo) -> {:next_state, :mining, data}
      has_mission_ore?(data) -> {:next_state, :delivering, data}
      true -> {:keep_state, data, [{:next_event, :internal, :cargo_to_sell}]}
    end
  end

  def selling(:internal, :cargo_to_sell, %__MODULE__{} = data) do
    %Fleet.Inventory{symbol: product, units: quantity} = data.cargo.inventory |> List.first()
    Logger.info("Selling #{quantity} units of #{product}")

    {:ok, %{"cargo" => cargo}} = LiveClient.sell(data.ship, product, quantity)
    data = struct!(data, cargo: Fleet.parse_cargo(cargo))

    if Fleet.empty_cargo?(data.cargo) do
      NervousBotWeb.Endpoint.broadcast("goods-sold", product, %{})
      {:next_state, :mining, data}
    else
      {:keep_state, data, [{:next_event, :internal, :cargo_to_sell}]}
    end
  end

  def mining(:enter, _, %__MODULE__{} = data) do
    :ok = Fleet.orbit(data.ship)
    maybe_mine(data)
  end

  def mining(:state_timeout, _, %__MODULE__{} = data) do
    maybe_mine(data)
  end

  def mining(:internal, :cargo_full, %__MODULE__{} = data) do
    :ok = Fleet.dock(data.ship)
    {:next_state, :selling, data, [{:next_event, :internal, :checking_stop}]}
  end

  ## Helpers

  defp has_mission_ore?(%__MODULE__{} = data) do
    Fleet.get_inventory_level(data.cargo, data.contract.ore) > 0
  end

  defp maybe_mine(%__MODULE__{cargo: cargo} = data) do
    if !Fleet.full_cargo?(cargo) do
      {:ok, %{"cooldown" => cooldown, "cargo" => cargo, "extraction" => extraction}} =
        LiveClient.extract(data.ship)

      Logger.info(
        "Excavated #{inspect(extraction["yield"])}. Waiting for #{cooldown["remainingSeconds"]}s."
      )

      data = struct!(data, cargo: Fleet.parse_cargo(cargo))
      {:keep_state, data, {:state_timeout, cooldown["remainingSeconds"] * 1000, :mining, []}}
    else
      {:keep_state_and_data, [{:next_event, :internal, :cargo_full}]}
    end
  end

  defp navigate(%__MODULE__{} = data, to) do
    {:ok, response} = LiveClient.navigate(data.ship, to)
    {:ok, arrival_time, _} = response["nav"]["route"]["arrival"] |> DateTime.from_iso8601()
    Timex.diff(arrival_time, DateTime.utc_now(), :seconds)
  end
end
