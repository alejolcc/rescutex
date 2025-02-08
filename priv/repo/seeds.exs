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

picture = fn ->
  images_path =
    :code.priv_dir(:rescutex)
    |> Path.join("static")
    |> Path.join("uploads")

  name =
    images_path
    |> File.ls!()
    |> Enum.random()

  "#{name}"
end

Enum.each(1..10, fn _ ->
  {lat, long} = point.()

  %Rescutex.Pets.Pet{
    age: age.(),
    details: "This is a pet",
    gender: gender.(),
    kind: kind.(),
    name: name.(),
    lat: lat,
    long: long,
    pictures: picture.(),
    race: race.()
  }
  |> Rescutex.Repo.insert!()
end)
