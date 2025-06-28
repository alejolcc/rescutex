defmodule Rescutex.PetsTest do
  use Rescutex.DataCase

  alias Rescutex.Pets

  describe "pets" do
    alias Rescutex.Pets.Pet

    import Rescutex.PetsFixtures

    @invalid_attrs %{
      name: nil,
      long: nil,
      details: nil,
      age: nil,
      lat: nil,
      pictures: nil,
      race: nil
    }

    test "list_pets/0 returns all pets" do
      pet = pet_fixture()
      assert Enum.member?(Pets.list_pets(), pet)
    end

    test "get_pet!/1 returns the pet with given id" do
      pet = pet_fixture()
      assert Pets.get_pet!(pet.id) == pet
    end

    test "create_pet/1 with valid data creates a pet" do
      valid_attrs = %{
        name: "some name",
        long: 120.5,
        details: "some details",
        kind: :dog,
        age: 42,
        lat: 120.5,
        pictures: ["some pictures"],
        race: "some race"
      }

      assert {:ok, %Pet{} = pet} = Pets.create_pet(valid_attrs)
      assert pet.name == "some name"
      assert pet.long == 120.5
      assert pet.details == "some details"
      assert pet.age == 42
      assert pet.lat == 120.5
      assert pet.pictures == ["some pictures"]
      assert pet.race == "some race"
    end

    test "create_pet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pets.create_pet(@invalid_attrs)
    end

    test "update_pet/2 with valid data updates the pet" do
      pet = pet_fixture()

      update_attrs = %{
        name: "some updated name",
        long: 456.7,
        details: "some updated details",
        age: 43,
        lat: 456.7,
        pictures: ["some updated pictures"],
        race: "some updated race"
      }

      assert {:ok, %Pet{} = pet} = Pets.update_pet(pet, update_attrs)
      assert pet.name == "some updated name"
      assert pet.long == 456.7
      assert pet.details == "some updated details"
      assert pet.age == 43
      assert pet.lat == 456.7
      assert pet.pictures == ["some updated pictures"]
      assert pet.race == "some updated race"
    end

    test "update_pet/2 with invalid data returns error changeset" do
      pet = pet_fixture()
      assert {:error, %Ecto.Changeset{}} = Pets.update_pet(pet, @invalid_attrs)
      assert pet == Pets.get_pet!(pet.id)
    end

    test "delete_pet/1 deletes the pet" do
      pet = pet_fixture()
      assert {:ok, %Pet{}} = Pets.delete_pet(pet)
      assert_raise Ecto.NoResultsError, fn -> Pets.get_pet!(pet.id) end
    end

    test "change_pet/1 returns a pet changeset" do
      pet = pet_fixture()
      assert %Ecto.Changeset{} = Pets.change_pet(pet)
    end
  end
end
