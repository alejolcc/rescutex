defmodule Rescutex.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    create table(:pets) do
      add :age, :integer
      add :details, :string
      add :gender, :string
      add :kind, :string
      add :name, :string
      add :lat, :float
      add :long, :float
      add :pictures, :string
      add :race, :string

      timestamps(type: :utc_datetime)
    end
  end
end
