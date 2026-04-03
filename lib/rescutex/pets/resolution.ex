defmodule Rescutex.Pets.Resolution do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rescutex.Pets.Pet
  alias Rescutex.Accounts.User

  @derive {Jason.Encoder,
           except: [:__struct__, :__meta__, :pet, :user, :matched_pet, :resolved_with_user]}
  schema "resolutions" do
    field :external_resolver_name, :string
    field :notes, :string

    belongs_to :pet, Pet
    belongs_to :user, User
    belongs_to :matched_pet, Pet
    belongs_to :resolved_with_user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resolution, attrs) do
    resolution
    |> cast(attrs, [
      :external_resolver_name,
      :notes,
      :matched_pet_id,
      :resolved_with_user_id,
      :pet_id,
      :user_id
    ])
    |> validate_required([:pet_id, :user_id])
    |> foreign_key_constraint(:pet_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:matched_pet_id)
    |> foreign_key_constraint(:resolved_with_user_id)
  end
end
