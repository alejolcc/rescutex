defmodule Rescutex.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :phone1, :string
    field :phone2, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone1, :phone2])
    |> validate_required([:name, :email, :phone1, :phone2])
  end
end
