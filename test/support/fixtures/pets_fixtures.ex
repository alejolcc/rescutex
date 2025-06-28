defmodule Rescutex.PetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rescutex.Pets` context.
  """

  @doc """
  Generate a pet.
  """
  def pet_fixture(attrs \\ %{}) do
    {:ok, pet} =
      attrs
      |> Enum.into(%{
        age: 42,
        details: "some details",
        lat: 120.5,
        long: 120.5,
        name: "some name",
        pictures: "some pictures",
        race: "some race",
        kind: "dog"
      })
      |> Rescutex.Pets.create_pet()

    pet
  end
end
