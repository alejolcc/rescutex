defmodule Rescutex.Pets.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rescutex.Pets.PetTag
  alias Rescutex.Pets.Tag

  @derive {Jason.Encoder, except: [:__struct__, :__meta__]}
  schema "pets" do
    field :name, :string
    field :long, :float
    field :details, :string
    field :gender, Ecto.Enum, values: [:female, :male]
    field :kind, Ecto.Enum, values: [:cat, :dog]
    field :age, :integer
    field :lat, :float
    field :pictures, {:array, :string}
    field :race, :string
    field :embedding, Pgvector.Ecto.Vector
    field :post_type, Ecto.Enum, values: [:found, :lost, :transit, :adoption]

    belongs_to :user, Rescutex.Accounts.User

    many_to_many :tags, Tag, join_through: PetTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [
      :age,
      :details,
      :name,
      :lat,
      :long,
      :pictures,
      :race,
      :embedding,
      :kind,
      :gender,
      :user_id,
      :post_type
    ])
    |> validate_required([:kind, :details, :name, :lat, :long, :pictures, :user_id, :post_type])
  end
end
