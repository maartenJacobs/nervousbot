defmodule NervousBot.Contracts.Contract do
  @type t :: %__MODULE__{
          id: String.t(),
          system: String.t(),
          waypoint: String.t(),
          ore: String.t()
        }

  defstruct [:id, :system, :waypoint, :ore]
end
