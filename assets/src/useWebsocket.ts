import { useEffect, useRef, useState } from "react";

type Message =
  | { action: "message"; username: string; message: string }
  | { action: "set_nickname"; nickname: string }
  | { action: "user_joined"; nickname: string }
  | { action: "user_left"; nickname: string };

interface Websocket {
  close: () => void;
  messages: ReadonlyArray<Message>;
  send: (msg: string) => void;
  ws: WebSocket | undefined;
  username: string | null;
}

export default (
  path: string,
  onMessage?: (message: Message) => void
): Websocket => {
  const ws = useRef<WebSocket>();
  const [messages, setMessages] = useState<ReadonlyArray<Message>>([]);
  const [username, setUsername] = useState(null);

  useEffect(() => {
    const socket = new WebSocket(path);
    ws.current = socket;
    ws.current.onmessage = ({ data }) => {
      const msg = JSON.parse(data);
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
