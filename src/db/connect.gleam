import gleam/pgo.{type Connection}

pub fn get_pool() -> Connection {
  pgo.connect(
    pgo.Config(
      ..pgo.default_config(),
      host: "localhost",
      port: 5432,
      pool_size: 10,
    ),
  )
}
