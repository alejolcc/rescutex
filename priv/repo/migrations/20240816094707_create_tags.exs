defmodule Rescutex.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :title, :string
      add :type, :string

      timestamps(type: :utc_datetime)
    end
  end
end
