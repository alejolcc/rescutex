defmodule Rescutex.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rescutex.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "some email",
        name: "some name",
        phone1: "some phone1",
        phone2: "some phone2"
      })
      |> Rescutex.Accounts.create_user()

    user
  end
end
