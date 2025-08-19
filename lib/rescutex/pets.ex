defmodule Rescutex.Pets do
  @moduledoc """
  The Pets context.
  """
  import Ecto.Query, warn: false
  import Geo.PostGIS
  import Pgvector.Ecto.Query

  require Logger
  alias Rescutex.Accounts.User
  alias Rescutex.Pets.Pet
  alias Rescutex.Repo
  alias Ecto.Changeset

  def get_similar_pets(pet, opts \\ []) do
    limit = Keyword.get(opts, :limit, 6)

    Repo.all(
      from p in Pet,
        where: p.kind == ^pet.kind,
        where: p.id != ^pet.id,
        order_by: l2_distance(p.embedding, ^pet.embedding),
        limit: ^limit
    )
  end

  @doc """
  Gets all pets that have a L2 distance lower than a given threshold from another pet.
  It only compares pets of the same kind.
  Returns an empty list if the pet has no embedding.
  """
  def get_similar_pets_within_distance(%Pet{embedding: nil}, _threshold), do: []

  def get_similar_pets_within_distance(%Pet{} = pet, threshold) do
    Repo.all(
      from p in Pet,
        where: p.kind == ^pet.kind,
        where: p.id != ^pet.id,
        where: l2_distance(p.embedding, ^pet.embedding) < ^threshold,
        order_by: l2_distance(p.embedding, ^pet.embedding)
    )
  end

  @doc """
  Used for debug purpouses
  Returns the L2 distance of all other pets from a given pet.

  It returns a list of `{pet_id, distance}` tuples.
  Returns an empty list if the pet has no embedding.

  """
  def get_all_pets_distances(%Pet{embedding: nil}), do: []

  def get_all_pets_distances(%Pet{} = pet) do
    query =
      from p in Pet,
        where: p.id != ^pet.id,
        order_by: [asc: l2_distance(p.embedding, ^pet.embedding)],
        select: {p.id, l2_distance(p.embedding, ^pet.embedding), p.name}

    Repo.all(query)
    |> Enum.sort_by(fn {_x, y, _} -> y end)
  end

  @doc """
  Returns the list of pets.

  ## Examples

      iex> list_pets()
      [%Pet{}, ...]

  """
  def list_pets(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Pet
    |> apply_filters(filters)
    |> Repo.all()
  end

  def list_pets_for_user(user, opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Pet
    |> where([p], p.user_id == ^user.id)
    |> apply_filters(filters)
    |> Repo.all()
  end

  @doc """
  Gets a single pet.

  Raises `Ecto.NoResultsError` if the Pet does not exist.

  ## Examples

      iex> get_pet!(123)
      %Pet{}

      iex> get_pet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pet!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [:user])

    Pet
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  @doc """
  Gets all lost pets.
  """
  def get_lost_pets() do
    from(p in Pet, where: p.post_type == :lost)
    |> Repo.all()
  end

  @doc """
  Creates a pet.
  """

  def create_pet(%User{} = user, attrs \\ %{}) do
    attrs = Map.put(attrs, "user_id", user.id)

    %Pet{}
    |> Pet.changeset(attrs)
    |> Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def get_lat(%Pet{} = pet) do
    {_long, lat} = pet.location.coordinates
    lat
  end

  def get_long(%Pet{} = pet) do
    {long, _lat} = pet.location.coordinates
    long
  end

  @doc """
  Updates a pet.

  ## Examples

      iex> update_pet(pet, %{field: new_value})
      {:ok, %Pet{}}

      iex> update_pet(pet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pet(%Pet{} = pet, attrs) do
    pet
    |> Pet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pet.

  ## Examples

      iex> delete_pet(pet)
      {:ok, %Pet{}}

      iex> delete_pet(pet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pet(%Pet{} = pet) do
    Repo.delete(pet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pet changes.

  ## Examples

      iex> change_pet(pet)
      %Ecto.Changeset{data: %Pet{}}

  """
  def change_pet(%Pet{} = pet, attrs \\ %{}) do
    Pet.changeset(pet, attrs)
  end

  @doc """
  Gets all pets within a given distance (in meters) from a location.

  The distance is calculated on a spheroid, so it is accurate.

  ## Examples

      iex> st_dwithin_in_meters(pet, 1000)
      [%Pet{}, ...]

  """
  def get_pets_in_area(pet, distance)
      when is_number(distance) do
    filters = [distance: {pet.location, distance}]

    query = from p in Pet, where: p.id != ^pet.id

    query
    |> apply_filters(filters)
    |> Repo.all()
  end

  @doc """
  Calculates the distance from a given pet to all other pets.

  Returns a list of maps, each containing the `:id` of another pet and its
  distance in meters from the given `pet`. The list is ordered by distance,
  from the closest to the farthest.

  The given pet itself is excluded from the results. If the given pet does
  not have a location, an empty list is returned.

  ## Examples

      iex> pet_with_location = %Rescutex.Pets.Pet{id: 1, location: %Geo.Point{coordinates: {-58.38, -34.60}, srid: 4326}}
      iex> # ... assume other pets exist in the database
      iex> list_pets_with_distance(pet_with_location)
      [%{id: 2, distance: 1234.56}, ...]

      iex> pet_without_location = %Rescutex.Pets.Pet{id: 4, location: nil}
      iex> list_pets_with_distance(pet_without_location)
      []
  """
  def list_pets_with_distance(%Pet{} = pet) do
    # Return an empty list if the source pet has no location
    if is_nil(pet.location) do
      []
    else
      from(p in Pet,
        # We don't want the source pet in the list
        where: p.id != ^pet.id,
        # Order the results by the closest distance first
        order_by: [asc: st_distance_in_meters(p.location, ^pet.location)],
        # Select a map containing the full pet struct and the calculated distance
        select: %{
          id: p.id,
          distance: st_distance_in_meters(p.location, ^pet.location)
        }
      )
      |> Repo.all()
    end
  end

  def apply_filters(query, []), do: query

  def apply_filters(query, [{_key, _val} = filter | rest]) do
    filter
    |> do_apply_filter(query)
    |> apply_filters(rest)
  end

  # Priv

  defp do_apply_filter({_, ""}, query), do: query
  defp do_apply_filter({_, nil}, query), do: query

  defp do_apply_filter({:distance, {point, meters}}, query) when is_number(meters) do
    from(q in query, where: st_dwithin_in_meters(q.location, ^point, ^meters))
  end

  defp do_apply_filter({:post_type, post_type}, query)
       when post_type in [:lost, :found, :transit, :adoption] do
    from(q in query, where: q.post_type == ^post_type)
  end

  defp do_apply_filter({:kind, kind}, query) when kind in [:dog, :cat] do
    from(q in query, where: q.kind == ^kind)
  end

  defp do_apply_filter(_, query) do
    query
  end

  @doc """
  Searches for pets based on distance, similarity, and kind.

  It finds pets that are:
  - Within a given `distance_in_meters` from the provided `pet`.
  - Have a `l2_distance` (embedding similarity) lower than the given `threshold`.
  - Are of the same `kind` as the `pet`.

  The results are ordered by embedding similarity first, and then by distance.
  Returns an empty list if the pet has no location or embedding, or if the
  required options are not provided.

  ## Examples

      iex> match_pets(pet, distance_in_meters: 5000, threshold: 0.5)
      [%Pet{}, ...]

  """
  def match_pets(%Pet{} = pet, opts \\ []) do
    distance_in_meters = Keyword.get(opts, :distance_in_meters, 10000)
    threshold = Keyword.get(opts, :threshold, 0.7)

    # Basic validation to ensure we have what we need.
    if is_nil(distance_in_meters) or is_nil(threshold) or is_nil(pet.location) or
         is_nil(pet.embedding) do
        Logger.warning("Missing field needed for matching")
      []
    else
      from(p in Pet,
        where: p.id != ^pet.id,
        where: p.kind == ^pet.kind,
        where: st_dwithin_in_meters(p.location, ^pet.location, ^distance_in_meters),
        where: l2_distance(p.embedding, ^pet.embedding) < ^threshold,
        order_by: [
          asc: l2_distance(p.embedding, ^pet.embedding),
          asc: st_distance_in_meters(p.location, ^pet.location)
        ]
      )
      |> Repo.all()
    end
  end
end
