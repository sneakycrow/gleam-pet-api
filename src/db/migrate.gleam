import birl.{now, to_naive_date_string}
import db/connect.{get_pool}
import gleam/dynamic
import gleam/erlang.{get_line}
import gleam/int
import gleam/io
import gleam/list.{each, filter, sort, try_map}
import gleam/option.{type Option, None, unwrap}
import gleam/order.{type Order}
import gleam/pgo.{type Connection, execute}
import gleam/string.{ends_with, replace, split, trim}
import simplifile.{
  create_directory_all, create_file, current_directory, describe_error, read,
  read_directory,
}

type Migration {
  Migration(date: Int, name: String, full_path: String)
}

type MigrationError {
  InvalidMigrationName
  FailedToRunMigration
}

fn migration_from_path(
  file_name: String,
  full_path_dir: String,
) -> Result(Migration, MigrationError) {
  let parts = split(file_name, on: "_")
  case parts {
    [date, name, ..] -> {
      // Convert the date to an integer
      let assert Ok(date) = int.parse(date)
      // Remove `.sql.` from the end of the name
      let name = replace(name, ".sql", "")
      // Construct the full path
      let full_path = full_path_dir <> "/" <> file_name
      Ok(Migration(date, name, full_path))
    }
    _ -> Error(InvalidMigrationName)
  }
}

fn sort_migration(a: Migration, b: Migration) -> Order {
  int.compare(a.date, b.date)
}

pub fn run() {
  // Get a database connection
  let pool = get_pool()
  let migrations_folder = get_migrations_folder(folder_override: None)
  // Get all of the sql files in the migrations folder
  let assert Ok(migration_files) = read_directory(migrations_folder)
  // Files are expected to be named like "20210101_migration_name.sql"
  // Parse file paths into Migration structs, then sort by date
  let filtered_migrations =
    filter(migration_files, fn(f) { ends_with(f, ".sql") })
  let assert Ok(migrations) =
    try_map(filtered_migrations, fn(m) {
      migration_from_path(m, migrations_folder)
    })
  let sorted_migrations = sort(migrations, by: sort_migration)
  // Run each migration consecutively
  each(sorted_migrations, fn(m) { run_migration(pool, m) })
  // TODO: Remove after implementing
  Nil
}

fn run_migration(
  connection: Connection,
  migration: Migration,
) -> Result(Nil, MigrationError) {
  // Read the contents of the migration file
  let assert Ok(contents) = read(migration.full_path)
  // Execute the contents of the migration file
  let return_type = dynamic.optional(dynamic.int)
  case execute(contents, connection, [], return_type) {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(FailedToRunMigration)
  }
}

pub fn create() {
  let migrations_folder = get_migrations_folder(folder_override: None)
  // Get name of migration from user input
  let assert Ok(mig_name) = get_line("Migration name: ")
  // Create a new file in the migrations folder with the current date and the name provided
  let date = now()
  let string_date = replace(to_naive_date_string(date), "-", "")
  // Make sure to trim newlines and spaces from the migration name
  let full_name = trim(string_date <> "_" <> trim(mig_name) <> ".sql")
  let full_path = migrations_folder <> "/" <> full_name
  // Create the file
  let file = create_file(full_path)
  case file {
    Error(err) ->
      io.println("Error creating new migration" <> describe_error(err))
    Ok(_) -> io.println("Migration created at: " <> full_path)
  }
}

pub fn main() {
  // create()
  run()
}

pub fn get_migrations_folder(folder_override folder: Option(String)) -> String {
  let default_migration_folder = "migrations"
  let migrations_dir = unwrap(folder, default_migration_folder)
  let assert Ok(dir) = current_directory()
  let full_path = dir <> "/" <> migrations_dir
  // Create the migrations folder if it doesn't exist
  let assert Ok(_) = create_directory_all(full_path)
  full_path
}
