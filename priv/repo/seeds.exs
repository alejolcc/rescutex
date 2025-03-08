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

age = fn -> Enum.random(1..10) end
gender = fn -> Enum.random([:male, :female]) end
kind = fn -> Enum.random([:dog, :cat]) end

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

File.read!("priv/repo/seed.json") |> Jason.decode!()
|> Enum.each(fn %{"embedding" => embedding, "picture" => picture} ->
  {lat, long} = point.()

  %Rescutex.Pets.Pet{
    age: age.(),
    details: "This is a pet",
    gender: gender.(),
    kind: kind.(),
    name: name.(),
    lat: lat,
    long: long,
    pictures: picture,
    embedding: embedding,
    race: race.()
  }
  |> Rescutex.Repo.insert!()
end)
