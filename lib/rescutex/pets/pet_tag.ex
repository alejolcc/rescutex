defmodule Rescutex.Pets.PetTag do
  @moduledoc """
  schema to handle the join pets and tags

  To create a pet <-> tag, you can use the following snippet:


  PetTag.changeset(%PetTag{}, %{pet_id: 4, tag_id: 1})

  case Repo.insert(changeset) do
    {:ok, assoc} -> # Assoc was created!
    {:error, changeset} -> # Handle the error
  end

  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Rescutex.Pets.Pet
  alias Rescutex.Pets.Tag

  @primary_key false
  schema "pets_tags" do
    belongs_to :pet, Pet
    belongs_to :tag, Tag

    timestamps()
  end

  @doc false
  def changeset(pet_tag, attrs) do
    pet_tag
    |> cast(attrs, [:pet_id, :tag_id])
    |> validate_required([:pet_id, :tag_id])
  end
end
