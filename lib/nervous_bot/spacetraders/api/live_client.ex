defmodule NervousBot.Spacetraders.Api.LiveClient do
  alias NervousBot.Spacetraders.Api.LiveHttpClient

  def agent() do
    with {:ok, %Tesla.Env{status: 200, body: body}} <- LiveHttpClient.agent() do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def contracts() do
    with {:ok, %Tesla.Env{status: 200, body: body}} <- LiveHttpClient.list_contracts() do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def ship_cargo(ship) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <- LiveHttpClient.get_ship_cargo(ship) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def orbit(ship) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <- LiveHttpClient.orbit_ship(ship) do
      {:ok, body["data"]["nav"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def dock(ship) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <- LiveHttpClient.dock_ship(ship) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def extract(ship) do
    with {:ok, %Tesla.Env{status: 201, body: body}} <- LiveHttpClient.extract(ship) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def sell(ship, product, quantity) do
    with {:ok, %Tesla.Env{status: 201, body: body}} <-
           LiveHttpClient.sell_cargo(ship, product, quantity) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def refuel(ship) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <- LiveHttpClient.refuel(ship) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def navigate(ship, waypoint) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <-
           LiveHttpClient.navigate_ship(ship, waypoint) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def deliver(contract, ship, product, quantity) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <-
           LiveHttpClient.deliver(contract, ship, product, quantity) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def shipyard(system, waypoint) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <-
           LiveHttpClient.get_shipyard(system, waypoint) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def waypoints(system) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <-
           LiveHttpClient.get_waypoints(system) do
      {:ok, body["data"]}
    else
      {:ok, response} -> parse_error(response)
    end
  end

  def parse_error(%Tesla.Env{status: 429}) do
    {:error, :rate_limited}
  end
end
