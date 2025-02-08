defmodule Rescutex.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :phone1, :string
      add :phone2, :string

      timestamps(type: :utc_datetime)
    end
  end
end
