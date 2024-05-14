import envoy
import gleam/int
import gleam/option.{Some}
import gleam/pgo.{type Connection}
import gleam/result

pub fn get_pool() -> Result(Connection, Nil) {
  use config <- result.try(get_db_config())
  Ok(pgo.connect(config))
}

pub fn get_db_config() -> Result(pgo.Config, Nil) {
  // Get the DB configuration from the environment
  use host <- result.try(envoy.get("DB_HOST"))
  use port <- result.try(envoy.get("DB_PORT"))
  // Convert the port to an integer
  use port <- result.try(int.parse(port))
  use user <- result.try(envoy.get("DB_USER"))
  use password <- result.try(envoy.get("DB_PASS"))
  use database <- result.try(envoy.get("DB_NAME"))
  Ok(
    pgo.Config(
      ..pgo.default_config(),
      host: host,
      port: port,
      user: user,
      password: Some(password),
      database: database,
    ),
  )
}
