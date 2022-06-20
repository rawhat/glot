import gleam/bit_builder
import gleam/bit_string
import gleam/http/request.{Request}
import gleam/http/response
import gleam/otp/process.{Sender}
import gleam/result
import gleam/string
import glot/lobby.{LobbyMessage}
import mist/file
import mist/http.{BitBuilderBody, FileBody, HandlerResponse, Response}

pub fn handler(app_request: AppRequest) -> AppResult {
  case request.path_segments(app_request.req) {
    ["static", ..path] | [] as path | ["favicon.ico"] as path ->
      serve_file(path, app_request.static_root)
    ["lobby"] ->
      app_request.lobby_handler
      |> lobby.lobby_handler
      |> Ok
  }
}

pub fn app_middleware(
  func: AppHandler,
  static_root: String,
  lobby_handler: Sender(LobbyMessage),
) -> http.HandlerFunc {
  fn(req: Request(BitString)) {
    AppRequest(req: req, static_root: static_root, lobby_handler: lobby_handler)
    |> func
    |> result.map_error(fn(err) {
      case err {
        NotFound ->
          response.new(404)
          |> response.set_body(BitBuilderBody(bit_builder.new()))
          |> Response
      }
    })
    |> result.unwrap_both
  }
}

pub type AppError {
  NotFound
}

pub type AppRequest {
  AppRequest(
    lobby_handler: Sender(LobbyMessage),
    req: Request(BitString),
    static_root: String,
  )
}

pub type AppResult =
  Result(HandlerResponse, AppError)

pub type AppHandler =
  fn(AppRequest) -> AppResult

pub fn from_app_error(err: AppError) -> HandlerResponse {
  case err {
    NotFound ->
      response.new(404)
      |> response.set_body(BitBuilderBody(bit_builder.new()))
      |> Response
  }
}

pub external fn get_cwd() -> Result(String, Nil) =
  "file" "get_cwd"

external fn file_extension(file: String) -> String =
  "filename" "extension"

external fn uri_unquote(uri: String) -> String =
  "uri_string" "unquote"

pub fn serve_file(path: List(String), root: String) -> AppResult {
  let decoded_path =
    path
    |> string.join("/")
    |> string.replace("..", "")
    |> uri_unquote
    |> fn(res) {
      case res {
        "" | "/" -> "index.html"
        _ -> res
      }
    }
    |> string.append(root, _)

  let path_bitstring = bit_string.from_string(decoded_path)

  try fd =
    file.open(path_bitstring)
    |> result.replace_error(NotFound)

  let size = file.size(path_bitstring)
  let content_type =
    decoded_path
    |> file_extension
    |> ext_to_content_type
  response.new(200)
  |> response.set_body(FileBody(fd, content_type, 0, size))
  |> response.prepend_header("Content-Type", content_type)
  |> Response
  |> Ok
}

fn ext_to_content_type(ext: String) -> String {
  case ext {
    "" -> "application/x-binary"
    ".gleam" -> "application/gleam"
    ".js" -> "text/javascript"
    ".css" -> "text/css"
    ".html" -> "text/html"
    ".gif" -> "application/gif"
    ".mkv" -> "video/x-matroska"
    ".avi" -> "video/avi"
    _ -> "text/plain"
  }
}
