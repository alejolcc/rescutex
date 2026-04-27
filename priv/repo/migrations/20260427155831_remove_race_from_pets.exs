defmodule Rescutex.Repo.Migrations.RemoveRaceFromPets do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      remove :race, :string
    end
  end
end
