defmodule Rescutex.Repo.Migrations.AddStatusToPets do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :status, :string, default: "open", null: false
    end
  end
end
