defmodule Rescutex.Repo.Migrations.AddLocationToPets do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :location, :geometry
    end

    execute "UPDATE pets SET location = ST_MakePoint(long, lat);"

    alter table(:pets) do
      remove :lat
      remove :long
    end

    create index(:pets, [:location], using: :gist)
  end
end
