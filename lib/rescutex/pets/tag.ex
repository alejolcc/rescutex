defmodule Rescutex.Pets.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rescutex.Pets.PetTag
  alias Rescutex.Pets.Pet

  schema "tags" do
    field :title, :string
    # TODO: Add all the types in an enum
    field :type, :string
    many_to_many :pets, Pet, join_through: PetTag

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:title, :type])
    |> validate_required([:title, :type])
  end
end
