defmodule Rescutex.Repo.Migrations.CreatePetsTags do
  use Ecto.Migration

  def change do
    create table(:pets_tags) do
      add :pet_id, references(:pets)
      add :tag_id, references(:tags)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pets_tags, [:pet_id, :tag_id])
  end
end
