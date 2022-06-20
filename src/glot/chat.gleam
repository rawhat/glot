import gleam/json

pub type ChatMessage {
  ChatMessage(username: String, message: String)
  SetNickname(nickname: String)
  UserJoined(nickname: String)
  UserLeft(nickname: String)
}

pub fn encode_chat_message(message: ChatMessage) -> String {
  case message {
    ChatMessage(username, message) ->
      json.object([
        #("action", json.string("message")),
        #("username", json.string(username)),
        #("message", json.string(message)),
      ])
      |> json.to_string
    SetNickname(nickname) ->
      json.object([
        #("action", json.string("set_nickname")),
        #("nickname", json.string(nickname)),
      ])
      |> json.to_string
    UserJoined(nickname) ->
      json.object([
        #("action", json.string("user_joined")),
        #("nickname", json.string(nickname)),
      ])
      |> json.to_string
    UserLeft(nickname) ->
      json.object([
        #("action", json.string("user_left")),
        #("nickname", json.string(nickname)),
      ])
      |> json.to_string
  }
}
