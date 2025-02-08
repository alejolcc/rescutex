defmodule Rescutex.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION vector;")

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
      add :embedding, :vector, size: 1408

      timestamps(type: :utc_datetime)
    end

    # Create the vector index (important for performance)
    execute("CREATE INDEX ON pets USING hnsw (embedding vector_l2_ops);") # hnsw is good for similarity search
  end
end
