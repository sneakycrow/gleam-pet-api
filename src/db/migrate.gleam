import birl.{now, to_naive_date_string}
import gleam/erlang.{get_line}
import gleam/io
import gleam/option.{type Option, None, unwrap}
import gleam/string.{replace, trim}
import simplifile.{
  create_directory_all, create_file, current_directory, describe_error,
  read_directory,
}

pub fn run() {
  let migrations_folder = get_migrations_folder(folder_override: None)
  // Get all of the sql files in the migrations folder
  let assert Ok(_migration_files) = read_directory(migrations_folder)
  // TODO: Sort the files by date
  // Files are expected to be named like "2021_01_01_migration_name.sql"
  // Run each sql file in order
  // io.debug(migration_files)
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
  let string_date = replace(to_naive_date_string(date), "-", "_")
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
  create()
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
