import gleam/erlang
import gleam/result
import gleam/string
import glot/lobby
import glot/router
import glot/util
import mist/http
import mist

pub fn main() {
  assert Ok(cwd) = util.get_cwd()

  assert Ok(lobby_handler) = lobby.start()
  let static_root = string.append(cwd, "/dist/")

  router.handler
  |> router.app_middleware(static_root, lobby_handler)
  |> http.handler_func
  |> mist.serve(8080, _)
  |> result.map(fn(_res) { erlang.sleep_forever() })
}
