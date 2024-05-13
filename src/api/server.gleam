import db/connect
import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}

pub fn index(request: Request(Connection)) -> Response(ResponseData) {
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
  let pool = connect.get_pool()
  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        [] -> index(req)
        _ -> not_found()
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}
