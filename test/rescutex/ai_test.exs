defmodule Rescutex.AITest do
  use Rescutex.DataCase
  alias Rescutex.AI
  import Rescutex.PetsFixtures
  alias Rescutex.AccountsFixtures

  setup do
    user = AccountsFixtures.user_fixture()
    pet = pet_fixture(user, %{"pictures" => ["test_pet.jpg"]})

    # Create dummy image in /tmp as expected by AI module
    File.write!("/tmp/test_pet.jpg", "dummy image content")

    on_exit(fn ->
      File.rm("/tmp/test_pet.jpg")
      File.rm("/tmp/test_pet_no_bg.jpg")
    end)

    %{pet: pet}
  end

  describe "calculate_embedding/1" do
    test "successfully updates pet with dummy embedding using Noop adapters", %{pet: pet} do
      assert {:ok, updated_pet} = AI.calculate_embedding(pet)
      assert updated_pet.embedding != nil
      
      # Convert Pgvector to list for verification
      embedding_list = Pgvector.to_list(updated_pet.embedding)
      
      # Noop embedder returns 1408 zeros
      assert Enum.count(embedding_list) == 1408
      assert Enum.all?(embedding_list, fn x -> x == 0.0 end)
    end
  end
end
