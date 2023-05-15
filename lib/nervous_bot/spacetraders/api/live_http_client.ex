defmodule NervousBot.Spacetraders.Api.LiveHttpClient do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.spacetraders.io/v2"
  plug Tesla.Middleware.BearerAuth, token: api_token()
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  plug Tesla.Middleware.Retry,
    delay: 500,
    max_retries: 3,
    max_delay: 10_000,
    should_retry: fn
      {:error, _} -> true
      {:ok, %{status: status}} when status in [429, 500] -> true
      _ -> false
    end

  plug NervousBot.Spacetraders.Api.LiveHttpClient.SessionLogger

  # =========
  # Account
  # =========

  def register(email, callsign, faction) do
    post("/register", %{
      "faction" => faction,
      "symbol" => callsign,
      "email" => email
    })
  end

  def agent() do
    get("/my/agent")
  end

  # =========
  # Ship
  # =========

  def buy_ship(at, type) do
    post("/my/ships", %{
      "waypointSymbol" => at,
      "shipType" => type
    })
  end

  def list_ships() do
    get("/my/ships")
  end

  def get_ship_details(ship_symbol) do
    get("/my/ships/#{ship_symbol}")
  end

  def get_ship_cargo(ship_symbol) do
    get("/my/ships/#{ship_symbol}/cargo")
  end

  def navigate_ship(ship_symbol, to_symbol) do
    post("/my/ships/#{ship_symbol}/navigate", %{waypointSymbol: to_symbol})
  end

  def dock_ship(ship_symbol) do
    post("/my/ships/#{ship_symbol}/dock", %{})
  end

  def orbit_ship(ship_symbol) do
    post("/my/ships/#{ship_symbol}/orbit", %{})
  end

  def sell_cargo(ship_symbol, cargo_symbol, quantity) do
    post("/my/ships/#{ship_symbol}/sell", %{symbol: cargo_symbol, units: quantity})
  end

  def extract(ship_symbol) do
    post("/my/ships/#{ship_symbol}/extract", %{})
  end

  def refuel(ship_symbol) do
    post("/my/ships/#{ship_symbol}/refuel", %{})
  end

  # =========
  # Contracts
  # =========

  def list_contracts() do
    get("/my/contracts")
  end

  def deliver(contract, ship, product, quantity) do
    post("/my/contracts/#{contract}/deliver", %{
      shipSymbol: ship,
      tradeSymbol: product,
      units: quantity
    })
  end

  # =========
  # Systems
  # =========

  def get_waypoints(system_symbol) do
    get("/systems/#{system_symbol}/waypoints")
  end

  def get_market(system_symbol, waypoint_symbol) do
    get("/systems/#{system_symbol}/waypoints/#{waypoint_symbol}/market")
  end

  def get_shipyard(system_symbol, waypoint_symbol) do
    get("/systems/#{system_symbol}/waypoints/#{waypoint_symbol}/shipyard")
  end

  # =========
  # Config
  # =========

  def config(), do: Application.get_env(:nervous_bot, :spacetraders)
  def api_token(), do: config()[:api_token]
end
