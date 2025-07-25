defmodule RescutexWeb.PageController do
  use RescutexWeb, :controller

  def home(conn, _params), do: redirect(conn, to: ~p"/pets")
end
