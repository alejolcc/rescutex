defmodule Rescutex.Pets do
  @moduledoc """
  The Pets context.
  """

  import Pgvector.Ecto.Query
  import Ecto.Query, warn: false
  alias Rescutex.Repo

  alias Rescutex.Pets.Pet

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
  def get_pets_within_distance(%Pet{embedding: nil}, _threshold), do: []

  def get_pets_within_distance(%Pet{} = pet, threshold) do
    Repo.all(
      from p in Pet,
        where: p.kind == ^pet.kind,
        where: p.id != ^pet.id,
        where: l2_distance(p.embedding, ^pet.embedding) < ^threshold,
        order_by: l2_distance(p.embedding, ^pet.embedding)
    )
  end

  @doc """
  Returns the L2 distance of all other pets from a given pet.

  It returns a list of `{pet_id, distance}` tuples.
  Returns an empty list if the pet has no embedding.
  """
  def get_all_pets_distances(%Pet{embedding: nil}), do: []

  def get_all_pets_distances(%Pet{} = pet) do
    query =
      from p in Pet,
        where: p.id != ^pet.id,
        select: {p.id, l2_distance(p.embedding, ^pet.embedding)}

    Repo.all(query)
  end

  @doc """
  Returns the list of pets.

  ## Examples

      iex> list_pets()
      [%Pet{}, ...]

  """
  def list_pets do
    Repo.all(Pet)
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
  def get_pet!(id), do: Repo.get!(Pet, id)

  @doc """
  Creates a pet.

  ## Examples

      iex> create_pet(%{field: value})
      {:ok, %Pet{}}

      iex> create_pet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pet(attrs \\ %{}) do
    %Pet{}
    |> Pet.changeset(attrs)
    |> Repo.insert()
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
end
