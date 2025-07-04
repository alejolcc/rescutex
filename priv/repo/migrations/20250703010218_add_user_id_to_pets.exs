defmodule Rescutex.Repo.Migrations.AddUserIdToPets do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :user_id, references(:users, on_delete: :nothing)
    end
  end
end
