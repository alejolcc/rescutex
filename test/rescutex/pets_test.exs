defmodule Rescutex.PetsTest do
  use Rescutex.DataCase

  alias Rescutex.Pets
  alias Rescutex.Pets.Pet
  import Rescutex.PetsFixtures
  alias Rescutex.AccountsFixtures

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
        "location" => %{"lat" => 10.0, "long" => 20.0},
        "details" => "some details",
        "kind" => :dog,
        "age" => 42,
        "pictures" => ["some pictures"],
        "race" => "some race",
        "post_type" => "found"
      }

      assert {:ok, %Pet{} = pet} = Pets.create_pet(user, valid_attrs)
      assert pet.name == "some name"
      assert pet.location.coordinates == {20.0, 10.0}
      assert pet.details == "some details"
      assert pet.age == 42
      assert pet.pictures == ["some pictures"]
      assert pet.race == "some race"
    end

    test "create_pet/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Pets.create_pet(user, @invalid_attrs)
    end

    test "update_pet/2 with valid data updates the pet", %{user: user} do
      pet = pet_fixture(user)

      update_attrs = %{
        "name" => "some updated name",
        "location" => %{"lat" => 15.0, "long" => 25.0},
        "details" => "some updated details",
        "age" => 43,
        "pictures" => ["some updated pictures"],
        "race" => "some updated race"
      }

      assert {:ok, %Pet{} = pet} = Pets.update_pet(pet, update_attrs)
      assert pet.name == "some updated name"
      assert pet.location.coordinates == {25.0, 15.0}
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

  describe "geospatial and similarity searches" do
    defp set_embedding(pet, vector) do
      pet |> Ecto.Changeset.change(embedding: Pgvector.new(vector)) |> Repo.update!()
    end

    test "get_pets_in_area/2 returns pets within distance", %{user: user} do
      # Buenos Aires center
      pet_main = pet_fixture(user, %{"location" => %{"lat" => -34.6037, "long" => -58.3816}})
      # ~1km away
      pet_near = pet_fixture(user, %{"location" => %{"lat" => -34.6137, "long" => -58.3816}})
      # ~20km away
      pet_far = pet_fixture(user, %{"location" => %{"lat" => -34.8037, "long" => -58.3816}})

      results = Pets.get_pets_in_area(pet_main, 5000)
      result_ids = Enum.map(results, & &1.id)

      assert Enum.member?(result_ids, pet_near.id)
      refute Enum.member?(result_ids, pet_far.id)
      refute Enum.member?(result_ids, pet_main.id)
    end

    test "list_pets_with_distance/1 returns distances to other pets", %{user: user} do
      pet1 = pet_fixture(user, %{"location" => %{"lat" => 0.0, "long" => 0.0}})
      pet2 = pet_fixture(user, %{"location" => %{"lat" => 0.0, "long" => 1.0}})

      distances = Pets.list_pets_with_distance(pet1)
      assert [%{id: id, distance: dist}] = distances
      assert id == pet2.id
      # ~111km per degree at equator
      assert_in_delta dist, 111_000, 1000
    end

    test "get_similar_pets/2 returns pets ordered by similarity", %{user: user} do
      pet_main = pet_fixture(user, %{"kind" => :dog}) |> set_embedding(Enum.map(1..1408, fn _ -> 0.0 end))
      pet_similar = pet_fixture(user, %{"kind" => :dog}) |> set_embedding(Enum.map(1..1408, fn _ -> 0.1 end))
      pet_different = pet_fixture(user, %{"kind" => :dog}) |> set_embedding(Enum.map(1..1408, fn _ -> 0.9 end))
      pet_other_kind = pet_fixture(user, %{"kind" => :cat}) |> set_embedding(Enum.map(1..1408, fn _ -> 0.0 end))

      results = Pets.get_similar_pets(pet_main)
      result_ids = Enum.map(results, & &1.id)

      assert List.first(result_ids) == pet_similar.id
      assert Enum.member?(result_ids, pet_different.id)
      refute Enum.member?(result_ids, pet_other_kind.id)
      refute Enum.member?(result_ids, pet_main.id)
    end

    test "match_pets/2 filters by both distance and similarity", %{user: user} do
      # Main pet
      pet_main = pet_fixture(user, %{"kind" => :dog, "location" => %{"lat" => 0.0, "long" => 0.0}})
      |> set_embedding(Enum.map(1..1408, fn _ -> 0.0 end))

      # Near and similar (Match)
      pet_match = pet_fixture(user, %{"kind" => :dog, "location" => %{"lat" => 0.01, "long" => 0.01}})
      |> set_embedding(Enum.map(1..1408, fn _ -> 0.1 end))

      # Near but different (No match - similarity)
      _pet_far_embedding = pet_fixture(user, %{"kind" => :dog, "location" => %{"lat" => 0.01, "long" => 0.01}})
      |> set_embedding(Enum.map(1..1408, fn _ -> 1.0 end))

      # Similar but far (No match - distance)
      _pet_far_distance = pet_fixture(user, %{"kind" => :dog, "location" => %{"lat" => 1.0, "long" => 1.0}})
      |> set_embedding(Enum.map(1..1408, fn _ -> 0.1 end))

      results = Pets.match_pets(pet_main, distance_in_meters: 5000, threshold: 5.0)
      result_ids = Enum.map(results, & &1.id)

      assert result_ids == [pet_match.id]
    end
  end
end
