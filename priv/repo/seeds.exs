# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Rescutex.Repo.insert!(%Rescutex.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Rescutex.Accounts
alias Rescutex.Pets

age = fn -> Enum.random(1..10) end
gender = fn -> Enum.random([:male, :female]) end
# kind = fn -> Enum.random([:dog, :cat]) end

name = fn ->
  Enum.random([
    "Tommy",
    "Siry",
    "Choclo",
    "Pudin",
    "Coco",
    "Baileys",
    "Rocky",
    "Luna",
    "Oliver",
    "Max"
  ])
end

race = fn -> Enum.random(["Chiwawa", "Beagle", "Terrier", "Silvestre"]) end

point = fn ->
  lat = :rand.uniform() * -1 + -32
  long = :rand.uniform() * -1 + -60
  {lat, long}
end

# pictures = fn ->
#   :code.priv_dir(:rescutex) |> Path.join("static") |> Path.join("uploads") |> File.ls!()
# end

IO.puts("Creating user...")

{:ok, user} =
  Accounts.register_user(%{
    "email" => "user@example.com",
    "password" => "supersecret"
  })

IO.puts("User created: user@example.com")

IO.puts("Seeding pets...")

File.read!("priv/repo/seed.json") |> Jason.decode!()
|> Enum.each(fn %{"embedding" => embedding, "picture" => picture} ->
  {lat, long} = point.()

  pet_attrs = %{
    user_id: user.id,
    age: age.(),
    details: "This is a pet",
    gender: gender.(),
    kind: :dog,
    name: name.(),
    location: %Geo.Point{coordinates: {long, lat}, srid: 4326, properties: {}},
    pictures: [picture],
    embedding: embedding,
    race: race.()
  }
  |> Rescutex.Repo.insert!()
end)

IO.puts("Pets seeded for user@example.com.")
