defmodule NervousBot.Agent do
  alias NervousBot.Spacetraders.Api.LiveClient

  def get() do
    LiveClient.agent()
  end
end
