defmodule NervousBot.Spacetraders.Api.LiveHttpClient.SessionLogger do
  ## Log storage

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def logs() do
    Agent.get(__MODULE__, & &1)
  end

  def append(log) do
    Agent.get_and_update(__MODULE__, fn logs ->
      new_logs = [log | logs]
      {length(new_logs), new_logs}
    end)
  end

  ## Tesla Middleware definition

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, _opts) do
    {duration, response} = :timer.tc(Tesla, :run, [env, next])

    response
    |> format(duration)
    |> append()

    response
  end

  defp format({:ok, response}, duration) do
    %{
      request: "#{response.method} #{response.url |> URI.new!() |> Map.get(:path)}",
      time: DateTime.utc_now(),
      duration: duration,
      response: response.status
    }
  end

  defp format({:error, reason}, duration) do
    %{
      request: "n/a",
      time: DateTime.utc_now(),
      duration: duration,
      response: reason
    }
  end
end
