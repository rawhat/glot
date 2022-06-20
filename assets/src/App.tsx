import * as React from "react";
import { useEffect, useRef, useState } from "react";

type MessageAction =
  | "message"
  | "set_nickname"
  | "user_joined"
  | "user_left"

type Message =
  | { action: "message", username: string, message: string }
  | { action: "set_nickname", nickname: string }
  | { action: "user_joined", nickname: string }
  | { action: "user_left", nickname: string }

const useWebsocket = (path: string, onMessage?: (message: Message) => void) => {
  const ws = useRef<WebSocket>();
  const [messages, setMessages] = useState<ReadonlyArray<Message>>([]);
  const [username, setUsername] = useState(null);

  useEffect(() => {
    const socket = new WebSocket(path);
    ws.current = socket;
    ws.current.onmessage = ({ data }) => {
      console.log("got some data", data)
      const msg = JSON.parse(data);
      console.log("got a message", msg);
      if (msg.action === "message") {
        onMessage?.(msg);
        setMessages((prev) => prev.concat(msg));
      } else if (msg.action === "set_nickname") {
        setUsername(msg.nickname);
      } else if (msg.action === "user_joined") {
        setMessages((prev) => prev.concat(msg));
      } else if (msg.action === "user_left") {
        setMessages((prev) => prev.concat(msg));
      }
    };
    return () => {
      ws.current?.close();
    };
  }, [path]);

  return {
    close: () => ws.current?.close(),
    messages,
    send: (message: string) => ws.current?.send(message),
    ws: ws.current,
    username,
  };
};

const App = () => {
  const ws = useWebsocket("ws://localhost:8080/lobby");
  const [text, setText] = useState("");
  const onSubmit = () => {
    ws.send(text);
    setText("");
  };
  (window as any).ws = ws;
  return (
    <div className="flex h-screen place-content-center place-items-center font-mono">
      <div className="container flex flex-col py-4 px-10 border-2 rounded-xl border-gray-600 h-5/6 bg-white">
        <div className="container flex-row max-h-full overflow-y-auto">
          {ws.messages.map((msg, index) => {
            if (msg.action === "message") {
              return (
                <div key={`${msg.username}-${msg.message}-${index}`} className="flex flex-row">
                  <span>{msg.username}:&nbsp;</span>
                  <span className="flex-wrap">{msg.message}</span>
                </div>
              );
            } else if (msg.action === "user_joined") {
              return (
                <div key={`${msg.nickname}-joined-${index}`}>
                  <span>{msg.nickname} just joined.</span>
                </div>
              )
            } else if (msg.action === "user_left") {
              return (
                <div key={`${msg.nickname}-joined-${index}`}>
                  <span>{msg.nickname} just left.</span>
                </div>
              )
            }
          })}
        </div>
        <div className="flex flex-row border-2 rounded-md border-gray-300 mt-auto p-2">
          <span className="border-r-2 border-gray-300 pr-2">
            {ws.username}
          </span>
          <input
            className="flex-1 pl-2 focus:outline-none bg-gray-50"
            onChange={(e) => setText(e.currentTarget.value)}
            onKeyUp={(e) => {
              if (e.key === "Enter") {
                onSubmit()
              }
            }}
            value={text}
          />
        </div>
      </div>
    </div>
  );
};

export default App;
