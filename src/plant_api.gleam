import api/server
import argv
import db/migrate
import gleam/io

pub fn main() {
  case argv.load().arguments {
    // start the server
    ["start"] -> {
      server.start()
    }
    // migrate the database
    ["migrate"] -> {
      migrate.run()
    }
    ["migrate", "create"] -> {
      migrate.create()
    }
    _ -> {
      io.println("usage: [start|migrate]")
    }
  }
}
