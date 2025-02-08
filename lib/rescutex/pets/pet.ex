defmodule Rescutex.Pets.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rescutex.Pets.PetTag
  alias Rescutex.Pets.Tag

  schema "pets" do
    field :name, :string
    field :long, :float
    field :details, :string
    field :gender, Ecto.Enum, values: [:female, :male]
    field :kind, Ecto.Enum, values: [:cat, :dog]
    field :age, :integer
    field :lat, :float
    field :pictures, :string
    field :race, :string
    field :embedding, Pgvector.Ecto.Vector

    many_to_many :tags, Tag, join_through: PetTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [:age, :details, :name, :lat, :long, :pictures, :race, :embedding])
    |> validate_required([:age, :details, :name, :lat, :long, :pictures, :race])
  end
end
