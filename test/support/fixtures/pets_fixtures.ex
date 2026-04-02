defmodule Rescutex.PetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rescutex.Pets` context.
  """

  @doc """
  Generate a pet.
  """
  def pet_fixture(user, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "age" => 42,
        "details" => "some details",
        "location" => %{"lat" => 120.5, "long" => 120.5},
        "name" => "some name",
        "pictures" => ["some pictures"],
        "race" => "some race",
        "kind" => :dog,
        "post_type" => :found
      })

    {:ok, pet} = Rescutex.Pets.create_pet(user, attrs)

    pet
  end
end
