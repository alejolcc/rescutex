defmodule RescutexWeb.PetLive.CardPetComponent do
  use RescutexWeb, :live_component

  import RescutexWeb.CustomComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.link navigate={~p"/pets/#{@pet.id}"}>
        <.pet_card src={@pet.pictures} name={@pet.name} text={@pet.details} />
      </.link>
    </div>
    """
  end
end
