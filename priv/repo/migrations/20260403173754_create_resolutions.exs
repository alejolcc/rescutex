defmodule Rescutex.Repo.Migrations.CreateResolutions do
  use Ecto.Migration

  def change do
    create table(:resolutions) do
      add :pet_id, references(:pets, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :matched_pet_id, references(:pets, on_delete: :nilify_all)
      add :resolved_with_user_id, references(:users, on_delete: :nilify_all)
      add :external_resolver_name, :string
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:resolutions, [:pet_id])
    create index(:resolutions, [:user_id])
    create index(:resolutions, [:matched_pet_id])
    create index(:resolutions, [:resolved_with_user_id])
  end
end
