defmodule Rescutex.Pets.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  alias Geo.Point

  @derive {Jason.Encoder, except: [:__struct__, :__meta__]}
  schema "pets" do
    field :name, :string
    field :location, Geo.PostGIS.Geometry
    field :details, :string
    field :gender, Ecto.Enum, values: [:female, :male]
    field :kind, Ecto.Enum, values: [:cat, :dog]
    field :age, :integer
    field :pictures, {:array, :string}
    field :embedding, Pgvector.Ecto.Vector
    field :post_type, Ecto.Enum, values: [:found, :lost, :transit, :adoption]
    field :status, Ecto.Enum, values: [:open, :resolved], default: :open

    belongs_to :user, Rescutex.Accounts.User
    has_one :resolution, Rescutex.Pets.Resolution

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [
      :age,
      :details,
      :name,
      :pictures,
      :embedding,
      :kind,
      :gender,
      :user_id,
      :post_type,
      :status
    ])
    |> cast_location(attrs)
    |> validate_required([
      :kind,
      :details,
      :location,
      :pictures,
      :user_id,
      :post_type
    ])
  end

  defp cast_location(changeset, attrs) do
    # Use case to safely extract lat and long from the attributes map
    # IMPORTANT: the order matters
    case {get_in(attrs, ["location", "long"]), get_in(attrs, ["location", "lat"])} do
      {long, lat} when is_float(lat) and is_float(long) ->
        # You could add more robust parsing/validation here
        location = %Point{coordinates: {long, lat}, srid: 4326, properties: %{}}

        # 3. Use put_change/3 to add the transformed value to the changeset
        put_change(changeset, :location, location)

      # If lat or long are missing, do nothing and let the later validation catch it
      _ ->
        changeset
    end
  end
end
