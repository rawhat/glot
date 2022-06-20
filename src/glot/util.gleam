pub external fn get_cwd() -> Result(String, Nil) =
  "file" "get_cwd"

pub external fn file_extension(file: String) -> String =
  "filename" "extension"

pub external fn uri_unquote(uri: String) -> String =
  "uri_string" "unquote"

pub fn ext_to_content_type(ext: String) -> String {
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
