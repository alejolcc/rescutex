defmodule RescutexWeb.SearchLiveTest do
  use RescutexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Rescutex.PetsFixtures
  import Rescutex.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  describe "Search" do
    test "renders search page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/search")

      assert html =~ "Search by Photo"
      assert html =~ "Location"
      assert html =~ "Kind"
      assert html =~ "Search Radius"
      assert html =~ "Photo"
      assert html =~ "Please select a location on the map"
    end

    test "validates search criteria", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search")

      # Initial state should show location message
      assert render(view) =~ "Please select a location on the map"

      # Try to submit without anything - should trigger changeset errors
      html = view |> form("#search-form") |> render_submit()
      assert html =~ "can&#39;t be blank"
    end

    test "performs a search successfully", %{conn: conn, user: user} do
      # The Noop embedder returns a 1408-dimensional vector of 0.0s
      zero_embedding = for(_ <- 1..1408, do: 0.0)

      # Buenos Aires coordinates
      lat = -34.60
      long = -58.38

      pet =
        pet_fixture(user, %{
          "name" => "Matching Pet",
          "kind" => "dog",
          "location" => %{"lat" => lat, "long" => long},
          "embedding" => zero_embedding
        })

      {:ok, view, _html} = live(conn, ~p"/search")

      # 1. Simulate geocoding event (from map)
      view
      |> render_hook("geocoding", %{
        "results" => %{
          "geometry" => %{
            "location" => %{"lat" => lat, "lng" => long}
          }
        }
      })

      # 2. Upload a photo
      photo =
        file_input(view, "#search-form", :photo, [
          %{
            last_modified: 1_594_171_879_000,
            name: "dog.jpg",
            content: "dummy image content",
            type: "image/jpeg"
          }
        ])

      render_upload(photo, "dog.jpg")

      # 3. Fill form and submit
      view
      |> form("#search-form", %{
        pet_search: %{
          kind: "dog",
          distance_in_meters: 10000
        }
      })
      |> render_submit()

      # 4. Simulate background job broadcasting results
      topic = Application.fetch_env!(:rescutex, :topic)
      Rescutex.Pets.broadcast(topic, {:search_results, [pet]})

      # 5. Assert results are displayed
      assert has_element?(view, "#pet-#{pet.id}")
      assert render(view) =~ "Matching Pet"
    end

    test "shows no results if no pets match", %{conn: conn, user: user} do
      # Create a pet far away
      pet =
        pet_fixture(user, %{
          "name" => "Far Away Pet",
          "kind" => "dog",
          "location" => %{"lat" => 0.0, "long" => 0.0}
        })

      {:ok, view, _html} = live(conn, ~p"/search")

      # Simulate geocoding in Buenos Aires
      view
      |> render_hook("geocoding", %{
        "results" => %{
          "geometry" => %{
            "location" => %{"lat" => -34.60, "lng" => -58.38}
          }
        }
      })

      # Upload a photo
      photo =
        file_input(view, "#search-form", :photo, [
          %{
            name: "dog.jpg",
            content: "dummy",
            type: "image/jpeg"
          }
        ])

      render_upload(photo, "dog.jpg")

      # Submit search
      view
      |> form("#search-form", %{pet_search: %{kind: "dog", distance_in_meters: 1000}})
      |> render_submit()

      # Simulate background job broadcasting empty results
      topic = Application.fetch_env!(:rescutex, :topic)
      Rescutex.Pets.broadcast(topic, {:search_results, []})

      # Assert no results found message
      assert render(view) =~ "No similar pets found within the selected criteria"
      refute has_element?(view, "#pet-#{pet.id}")
    end

    test "cancels an upload", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search")

      photo =
        file_input(view, "#search-form", :photo, [
          %{
            name: "dog.jpg",
            content: "dummy",
            type: "image/jpeg"
          }
        ])

      render_upload(photo, "dog.jpg")

      # The entry name "dog.jpg" isn't rendered, but the cancel button is.
      assert has_element?(view, "button[phx-click='cancel-upload']")

      # Find the ref and click cancel
      html = render(view)
      [ref] = Regex.run(~r/phx-value-ref="([^"]+)"/, html, capture: :all_but_first)

      view
      |> element("button[phx-click='cancel-upload'][phx-value-ref='#{ref}']")
      |> render_click()

      refute has_element?(view, "button[phx-click='cancel-upload']")
    end
  end
end
