defmodule Rescutex.Repo.Migrations.DropTagsTables do
  use Ecto.Migration

  def up do
    drop table(:pets_tags)
    drop table(:tags)
  end

  def down do
    create table(:tags) do
      add :title, :string
      add :type, :string

      timestamps()
    end

    create table(:pets_tags) do
      add :pet_id, references(:pets)
      add :tag_id, references(:tags)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pets_tags, [:pet_id, :tag_id])
  end
end
