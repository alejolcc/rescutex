defmodule RescutexWeb.Router do
  use RescutexWeb, :router

  import RescutexWeb.UserAuth

  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RescutexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :get_google_api_key
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RescutexWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/map", MapLive, :index
    live "/search", SearchLive, :index
  end

  ## Authentication routes

  scope "/", RescutexWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{RescutexWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new

      # Publicly accessible list (lost/found/etc)
      live "/pets", PetLive.Index, :index
    end
  end

  scope "/", RescutexWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{RescutexWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", RescutexWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RescutexWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/users/my_pets", UserLive.PetsLive, :index

      # Protected Pet routes
      live "/pets/new", PetLive.Index, :new
      live "/pets/:id", PetLive.Show, :show
      delete "/users/log_out", UserSessionController, :delete
    end
  end

  scope "/auth", RescutexWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rescutex, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RescutexWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/" do
    pipe_through [:browser, :admins_only]
    oban_dashboard("/oban")
  end

  defp admins_only(conn, _opts) do
    auth_config = Application.fetch_env!(:rescutex, :oban_dashboard_auth)
    username = auth_config[:username]
    password = auth_config[:password]

    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
