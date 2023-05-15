defmodule NervousBot.Fleet.Cargo do
  alias NervousBot.Fleet.Inventory

  @type t :: %__MODULE__{
          capacity: integer(),
          units: integer(),
          inventory: [Inventory.t()]
        }

  defstruct [:capacity, :units, :inventory]
end
