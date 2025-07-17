defmodule Rescutex.PetsTest do
  use Rescutex.DataCase

  alias Rescutex.Pets
  alias Rescutex.Pets.Pet
  import Rescutex.PetsFixtures
  alias  Rescutex.AccountsFixtures

  setup do
    user = AccountsFixtures.user_fixture()
    %{user: user}
  end

  describe "pets" do
    @invalid_attrs %{
      "name" => nil,
      "details" => nil,
      "age" => nil,
      "location" => nil,
      "pictures" => nil,
      "race" => nil
    }
    test "list_pets/0 returns all pets", %{user: user} do
      pet = pet_fixture(user)
      pets = Pets.list_pets() |> Enum.map(& &1.id)
      assert Enum.member?(pets, pet.id)
    end

    test "get_pet!/1 returns the pet with given id", %{user: user} do
      pet = pet_fixture(user)
      assert pet == Pets.get_pet!(pet.id) |> Repo.preload(:user)
    end

    test "create_pet/1 with valid data creates a pet", %{user: user} do
      valid_attrs = %{
        "name" => "some name",
        "location" => %{"lat" => 120.5, "long" => 120.5},
        "details" => "some details",
        "kind" => :dog,
        "age" => 42,
        "pictures" => ["some pictures"],
        "race" => "some race",
        "post_type" => "found"
      }

      assert {:ok, %Pet{} = pet} = Pets.create_pet(user, valid_attrs)
      assert pet.name == "some name"
      assert pet.location.coordinates == {120.5, 120.5}
      assert pet.details == "some details"
      assert pet.age == 42
      assert pet.pictures == ["some pictures"]
      assert pet.race == "some race"
    end

    test "create_pet/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Pets.create_pet(user, @invalid_attrs)
    end

    @tag :skip
    test "update_pet/2 with valid data updates the pet", %{user: user} do
      pet = pet_fixture(user)

      update_attrs = %{
        name: "some updated name",
        location: %{"lat" => 456.7, "long" => 456.7},
        details: "some updated details",
        age: 43,
        pictures: ["some updated pictures"],
        race: "some updated race"
      }

      assert {:ok, %Pet{} = pet} = Pets.update_pet(pet, update_attrs)
      assert pet.name == "some updated name"
      assert pet.location.coordinates == {456.7, 456.7}
      assert pet.details == "some updated details"
      assert pet.age == 43
      assert pet.pictures == ["some updated pictures"]
      assert pet.race == "some updated race"
    end

    test "update_pet/2 with invalid data returns error changeset", %{user: user} do
      pet = pet_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Pets.update_pet(pet, @invalid_attrs)
      assert pet == Pets.get_pet!(pet.id) |> Repo.preload(:user)
    end

    test "delete_pet/1 deletes the pet", %{user: user} do
      pet = pet_fixture(user)
      assert {:ok, %Pet{}} = Pets.delete_pet(pet)
      assert_raise Ecto.NoResultsError, fn -> Pets.get_pet!(pet.id) end
    end

    test "change_pet/1 returns a pet changeset", %{user: user} do
      pet = pet_fixture(user)
      assert %Ecto.Changeset{} = Pets.change_pet(pet)
    end
  end
end
