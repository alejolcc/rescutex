defmodule RescutexWeb.AuthController do
  use RescutexWeb, :controller
  plug Ueberauth

  require Logger

  alias Rescutex.Accounts
  alias RescutexWeb.UserAuth
  def callback(%{assigns: %{ueberauth_failure: %{provider: :google, errors: errors}}} = conn, _params) do
    Logger.error("Failed to authenticate: #{inspect(errors)}")
    conn
    |> put_flash(:error, "Failed to authenticate")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email

    case Accounts.get_user_by_email(email) do
      nil ->
        # User does not exist, so create a new user
        user_params = %{
          email: email,
          first_name: auth.info.first_name,
          last_name: auth.info.last_name
        }

        case Accounts.register_oauth_user(user_params) do
          {:ok, user} ->
            UserAuth.log_in_user(conn, user)

          {:error, changeset} ->
            Logger.error("Failed to create user #{inspect(changeset)}.")

            conn
            |> put_flash(:error, "Failed to create user.")
            |> redirect(to: ~p"/")
        end

      user ->
        # User exists, update session or other details if necessary
        UserAuth.log_in_user(conn, user)
    end

    conn
    |> put_flash(:info, "Successfully authenticated (#{auth.info.email})")
    |> redirect(to: "/")
  end
end
