import gleam/int
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/otp/actor
import gleam/otp/process.{Sender}
import gleam/string
import glisten/tcp
import glot/chat.{ChatMessage, SetNickname, UserJoined, UserLeft}
import mist/http
import mist/websocket.{TextMessage}

pub type LobbyMessage {
  Connect(Sender(tcp.HandlerMessage))
  Disconnect(Sender(tcp.HandlerMessage))
  Message(from: Sender(tcp.HandlerMessage), message: String)
}

pub type User {
  User(sender: Sender(tcp.HandlerMessage), username: String)
}

pub type LobbyState {
  LobbyState(users: Map(Sender(tcp.HandlerMessage), User))
}

pub fn start() -> Result(Sender(LobbyMessage), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let #(_sender, receiver) = process.new_channel()
      actor.Ready(LobbyState(map.new()), Some(receiver))
    },
    init_timeout: 1_000,
    loop: fn(msg, state) {
      case msg {
        Connect(sender) -> {
          let user = User(sender, random_username())
          let set_nickname =
            SetNickname(user.username)
            |> chat.encode_chat_message
            |> TextMessage
          let _ = websocket.send(sender, set_nickname)
          let new_users = map.insert(state.users, sender, user)
          broadcast(new_users, UserJoined(user.username))
          LobbyState(users: new_users)
        }
        Disconnect(sender) -> {
          assert Ok(user) = map.get(state.users, sender)
          let new_users = map.delete(state.users, sender)
          broadcast(new_users, UserLeft(user.username))
          LobbyState(users: new_users)
        }
        Message(from, message) -> {
          assert Ok(user) = map.get(state.users, from)
          let msg = ChatMessage(user.username, message)
          broadcast(state.users, msg)
          state
        }
      }
      |> actor.Continue
    },
  ))
}

pub fn broadcast(
  users: Map(Sender(tcp.HandlerMessage), User),
  message: ChatMessage,
) -> Nil {
  users
  |> map.values
  |> list.each(send_to_user(_, message))
}

pub fn lobby_handler(lobby: Sender(LobbyMessage)) -> http.HandlerResponse {
  fn(message, sender) {
    assert websocket.TextMessage(message) = message
    let msg = Message(from: sender, message: message)
    let _ = process.send(lobby, msg)
    Ok(Nil)
  }
  |> websocket.with_handler
  |> websocket.on_init(fn(sender) {
    let _ = process.send(lobby, Connect(sender))
    Nil
  })
  |> websocket.on_close(fn(sender) {
    let _ = process.send(lobby, Disconnect(sender))
    Nil
  })
  |> http.Upgrade
}

fn send_to_user(user: User, message: ChatMessage) -> Nil {
  let encoded = chat.encode_chat_message(message)
  let _ = websocket.send(user.sender, TextMessage(encoded))

  Nil
}

fn random_username() -> String {
  int.random(1000, 9999)
  |> int.to_string
  |> string.append("user-", _)
}
