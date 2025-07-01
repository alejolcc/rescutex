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

    @tag :wip
    test "saves new pet", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/pets")

      # Click the "Add Pet" link, which triggers a live_redirect to /pets/new
      {:ok, form_live} =
        index_live
        |> element("a[href*='/pets/new']")
        |> render_click()
        |> follow_redirect(conn)

      # Assert that the new pet form is displayed
      html = render(form_live)
      assert html =~ "New Pet"

      # Test invalid submission
      assert form_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # Test valid submission and redirect back to index
      {:ok, index_live_after_save} =
        form_live
        |> form("#pet-form", pet: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      # Assert success message on the index page
      html = render(index_live_after_save)
      assert html =~ "Pet created successfully"
    end

    @tag :wip
    test "updates pet in listing", %{conn: conn, pet: pet} do
      {:ok, index_live, html} = live(conn, ~p"/pets/#{pet.id}/edit")

      assert html =~ "Edit Pet"

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

    # test "deletes pet in listing", %{conn: conn, pet: pet} do
    #   {:ok, index_live, _html} = live(conn, ~p"/pets")

    #   assert index_live |> element("#pet-#{pet.id} button[phx-click*='delete']") |> render_click()
    #   refute has_element?(index_live, "#pet-#{pet.id}")
    # end
  end

  describe "Show" do
    setup [:create_pet]

    test "displays pet", %{conn: conn, pet: pet} do
      {:ok, _show_live, html} = live(conn, ~p"/pets/#{pet}")

      assert html =~ "Show Pet"
    end

    test "updates pet within modal", %{conn: conn, pet: pet} do
      {:ok, show_live, _html} = live(conn, ~p"/pets/#{pet}")

      {:ok, pet_form_live} = show_live |> live(~p"/pets/#{pet.id}/show/edit")

      assert pet_form_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert pet_form_live
             |> form("#pet-form", pet: @update_attrs)
             |> render_submit()

      assert_patch(pet_form_live, ~p"/pets/#{pet}")

      html = render(show_live)
      assert html =~ "Pet updated successfully"
    end
  end
end
