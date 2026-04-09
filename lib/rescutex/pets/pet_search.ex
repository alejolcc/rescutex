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
    |> cast(attrs, [:kind, :distance_in_meters, :image_data])
    |> cast_location(attrs)
    |> validate_required([:kind, :image_data, :location])
    |> validate_inclusion(:kind, [:dog, :cat])
  end

  defp cast_location(changeset, attrs) do
    case Map.get(attrs, "location") || Map.get(attrs, :location) do
      %Geo.Point{} = point ->
        put_change(changeset, :location, point)

      %{"lat" => lat, "long" => long} ->
        # Coordinates can be strings or floats depending on where they come from (form vs manual)
        lat = to_float(lat)
        long = to_float(long)
        location = %Geo.Point{coordinates: {long, lat}, srid: 4326, properties: %{}}
        put_change(changeset, :location, location)

      _ ->
        changeset
    end
  end

  defp to_float(val) when is_binary(val), do: String.to_float(val)
  defp to_float(val) when is_number(val), do: val / 1
  defp to_float(_), do: nil
end
