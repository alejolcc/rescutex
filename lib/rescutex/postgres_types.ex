Postgrex.Types.define(
  Rescutex.PostgrexTypes,
  [Geo.PostGIS.Extension] ++ Pgvector.extensions() ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
