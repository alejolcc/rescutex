defmodule RescutexWeb.PetLiveTest do
  use RescutexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Rescutex.PetsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_pet(_) do
    pet = pet_fixture()
    %{pet: pet}
  end

  describe "Index" do
    setup [:create_pet]

    test "lists all pets", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/pets")

      assert html =~ "Listing Pets"
    end

    test "saves new pet", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/pets")

      assert index_live |> element("a[href*='/pets/new']") |> render_click() =~
               "New Pet"

      assert_patch(index_live, ~p"/pets/new")

      assert index_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#pet-form", pet: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/pets")

      html = render(index_live)
      assert html =~ "Pet created successfully"
    end

    test "updates pet in listing", %{conn: conn, pet: pet} do
      {:ok, index_live, _html} = live(conn, ~p"/pets")

      assert index_live |> element("#pet-#{pet.id} button[phx-click*='edit']") |> render_click() =~
               "Edit Pet"

      assert_patch(index_live, ~p"/pets/#{pet}/edit")

      assert index_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#pet-form", pet: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/pets")

      html = render(index_live)
      assert html =~ "Pet updated successfully"
    end

    test "deletes pet in listing", %{conn: conn, pet: pet} do
      {:ok, index_live, _html} = live(conn, ~p"/pets")

      assert index_live |> element("#pet-#{pet.id} button[phx-click*='delete']") |> render_click()
      refute has_element?(index_live, "#pet-#{pet.id}")
    end
  end

  describe "Show" do
    setup [:create_pet]

    test "displays pet", %{conn: conn, pet: pet} do
      {:ok, _show_live, html} = live(conn, ~p"/pets/#{pet}")

      assert html =~ "Show Pet"
    end

    test "updates pet within modal", %{conn: conn, pet: pet} do
      {:ok, show_live, _html} = live(conn, ~p"/pets/#{pet}")

      assert show_live |> element("button[phx-click*='edit']") |> render_click() =~
               "Edit Pet"

      assert_patch(show_live, ~p"/pets/#{pet}/show/edit")

      assert show_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#pet-form", pet: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/pets/#{pet}")

      html = render(show_live)
      assert html =~ "Pet updated successfully"
    end
  end
end
