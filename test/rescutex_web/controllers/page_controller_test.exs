defmodule RescutexWeb.PageControllerTest do
  use RescutexWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn, 302) =~ "/pets"
  end
end
