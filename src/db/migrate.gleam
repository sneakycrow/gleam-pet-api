import birl.{now, to_naive_date_string}
import gleam/erlang.{get_line}
import gleam/int
import gleam/io
import gleam/list.{sort, try_map}
import gleam/option.{type Option, None, unwrap}
import gleam/order.{type Order}
import gleam/string.{replace, split, trim}
import simplifile.{
  create_directory_all, create_file, current_directory, describe_error,
  read_directory,
}

type Migration {
  Migration(date: Int, name: String, full_path: String)
}

type MigrationError {
  InvalidMigrationName
}

fn migration_from_path(path: String) -> Result(Migration, MigrationError) {
  let parts = split(path, on: "_")
  case parts {
    [date, name, ..] -> {
      // Convert the date to an integer
      let assert Ok(date) = int.parse(date)
      Ok(Migration(date, name, path))
    }
    _ -> Error(InvalidMigrationName)
  }
}

fn sort_migration(a: Migration, b: Migration) -> Order {
  int.compare(a.date, b.date)
}

pub fn run() {
  let migrations_folder = get_migrations_folder(folder_override: None)
  // Get all of the sql files in the migrations folder
  let assert Ok(migration_files) = read_directory(migrations_folder)
  // Files are expected to be named like "20210101_migration_name.sql"
  // Parse file paths into Migration structs, then sort by date
  let assert Ok(migrations) = try_map(migration_files, migration_from_path)
  io.println("Migrations before sort: \n")
  io.debug(migrations)
  let sorted_migrations = sort(migrations, by: sort_migration)
  io.println("Migrations after sort: \n")
  io.debug(sorted_migrations)
  // TODO: Run each sql file in order
  // TODO: Remove after implementing
  Nil
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
