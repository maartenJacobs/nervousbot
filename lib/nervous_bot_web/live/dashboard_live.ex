defmodule NervousBotWeb.DashboardLive do
  alias NervousBot.Spacetraders.Api.LiveClient
  alias NervousBot.Spacetraders.Api.LiveHttpClient.SessionLogger
  use NervousBotWeb, :live_view

  @goods_topic "goods-sold"
  @contract_topic "contract-delivered"

  def mount(_params, _session, socket) do
    NervousBotWeb.Endpoint.subscribe(@goods_topic)
    NervousBotWeb.Endpoint.subscribe(@contract_topic)

    socket =
      if connected?(socket) do
        Process.send_after(self(), :refresh_logs, 1_000)

        socket
        |> assign(:agent, fetch_agent())
        |> assign(:contracts, fetch_contracts())
      else
        socket
        |> assign(:agent, nil)
        |> assign(:contracts, nil)
      end
      |> assign(:logs, fetch_logs())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <%= if @agent do %>
      <h1>ようこそ Agent <%= @agent["symbol"] %></h1>
      <h2>
        <.icon name="hero-currency-yen" class="h-4 w-4" />
        <%= @agent["credits"] %>
      </h2>
    <% else %>
      Loading agent...
    <% end %>

    <div class="mt-4 flex flex-col lg:grid lg:grid-cols-2 lg:gap-2">
      <div class="order-last lg:order-none">
        <h2 class="font-bold">Logs</h2>
        <.table id="logs" rows={@logs}>
          <:col :let={log} label="at">
            <%= log.time |> format_date() %>
          </:col>
          <:col :let={log} label="request">
            <%= log.request %>
          </:col>
          <:col :let={log} label="duration">
            <%= log.duration / 1000 %>ms
          </:col>
          <:col :let={log} label="response">
            <%= log.response %>
          </:col>
        </.table>
      </div>

      <div class="order-first lg:order-none">
        <h2 class="font-bold">Contracts</h2>

        <p :if={!@contracts}>Loading contracts...</p>

        <.table :if={@contracts} id="contracts" rows={@contracts}>
          <:col :let={contract} label="due">
            <%= contract["terms"]["deadline"]
            |> parse_iso8601!()
            |> format_date() %>
          </:col>
          <:col :let={contract} label="terms">
            <%= contract["terms"]["deliver"] |> Enum.map(&format_contract_terms/1) %>
          </:col>
        </.table>
      </div>
    </div>
    """
  end

  def handle_info(%{topic: @goods_topic}, socket) do
    {:noreply, assign(socket, :agent, fetch_agent())}
  end

  def handle_info(%{topic: @contract_topic}, socket) do
    {:noreply, assign(socket, :contracts, fetch_contracts())}
  end

  def handle_info(:refresh_logs, socket) do
    Process.send_after(self(), :refresh_logs, 1_000)

    {:noreply, assign(socket, :logs, fetch_logs())}
  end

  defp fetch_agent() do
    NervousBot.Agent.get()
    |> case do
      {:ok, agent} -> agent
      _ -> nil
    end
  end

  defp fetch_contracts() do
    LiveClient.contracts()
    |> case do
      {:ok, contracts} -> contracts
      _ -> nil
    end
  end

  defp fetch_logs() do
    SessionLogger.logs()
  end

  defp parse_iso8601!(date_string) do
    {:ok, date, _} = DateTime.from_iso8601(date_string)
    date
  end

  defp format_date(date) do
    Timex.format!(date, "{h24}:{m}:{s} {0D}/{0M}/{YYYY}")
  end

  defp format_contract_terms(%{
         "unitsRequired" => required,
         "unitsFulfilled" => fulfilled,
         "tradeSymbol" => symbol
       }) do
    percentage_done = (fulfilled / required * 100) |> floor()
    "#{symbol} #{fulfilled}/#{required} (#{percentage_done}% done)"
  end
end
