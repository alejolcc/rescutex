defmodule Rescutex.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS vector;")
    execute("CREATE EXTENSION IF NOT EXISTS postgis;")

    create table(:pets) do
      add :age, :integer
      add :details, :text
      add :gender, :string
      add :kind, :string
      add :post_type, :string
      add :name, :string
      add :location, :geometry
      add :pictures, {:array, :string}, null: false, default: []
      add :race, :string
      add :embedding, :vector, size: 1408

      timestamps(type: :utc_datetime)
    end

    create index(:pets, [:kind])
    create index(:pets, [:gender])
    create index(:pets, [:location], using: :gist)

    # Create the vector index (important for performance)
    # hnsw is good for similarity search
    execute("CREATE INDEX ON pets USING hnsw (embedding vector_l2_ops);")
  end
end
