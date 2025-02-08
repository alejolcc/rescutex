  Postgrex.Types.define(
    Rescutex.PostgrexTypes,
    Pgvector.extensions() ++ Ecto.Adapters.Postgres.extensions(),
    []
  )
