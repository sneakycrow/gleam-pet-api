import api/context.{Context}
import api/router
import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/response.{type Response}
import mist.{type ResponseData}
import wisp

pub fn index() -> Response(ResponseData) {
  let body = mist.Bytes(bytes_builder.from_string("Welcome to the Pet API"))

  response.new(200)
  |> response.prepend_header("made-by", "sneaky crow")
  |> response.set_body(body)
}

pub fn not_found() -> Response(ResponseData) {
  let body = mist.Bytes(bytes_builder.from_string("Not found"))

  response.new(404)
  |> response.set_body(body)
}

pub fn start() {
  // Start Logger
  wisp.configure_logger()
  // Create router
  let ctx = Context(static_directory: "priv/static", items: [])
  let handler = router.handle_request(_, ctx)
  let assert Ok(_) =
    wisp.mist_handler(handler, "")
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}
