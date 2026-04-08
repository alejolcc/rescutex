defmodule Rescutex.Pets.PetSearch do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :kind, Ecto.Enum, values: [:dog, :cat]
    field :location, Geo.PostGIS.Geometry
    field :distance_in_meters, :integer, default: 10000
    field :image_data, :binary, virtual: true
    field :embedding, Pgvector.Ecto.Vector
  end

  @doc false
  def changeset(pet_search, attrs) do
    pet_search
    |> cast(attrs, [:kind, :distance_in_meters, :image_data, :location])
    |> validate_required([:kind, :image_data, :location])
    |> validate_inclusion(:kind, [:dog, :cat])
  end
end
