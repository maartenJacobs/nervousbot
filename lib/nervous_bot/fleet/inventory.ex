defmodule NervousBot.Fleet.Inventory do
  @type t :: %__MODULE__{
          description: String.t(),
          name: String.t(),
          symbol: String.t(),
          units: String.t()
        }

  defstruct [:description, :name, :symbol, :units]
end
