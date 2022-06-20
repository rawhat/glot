import * as React from "react";
import { useState } from "react";
import useWebsocket from "./useWebsocket";

const App = () => {
  const ws = useWebsocket("ws://localhost:8080/lobby");
  const [text, setText] = useState("");
  const onSubmit = () => {
    if (text !== "") {
      ws.send(text);
      setText("");
    }
  };
  return (
    <div className="flex h-screen place-content-center place-items-center font-mono">
      <div className="container flex flex-col py-4 px-10 border-2 rounded-xl border-gray-600 h-5/6 bg-white">
        <div className="container flex-row max-h-full overflow-y-auto">
          {ws.messages.map((msg, index) => {
            if (msg.action === "message") {
              return (
                <div
                  key={`${msg.username}-${msg.message}-${index}`}
                  className="flex flex-row"
                >
                  <span>{msg.username}:&nbsp;</span>
                  <span className="flex-wrap">{msg.message}</span>
                </div>
              );
            } else if (msg.action === "user_joined") {
              return (
                <div key={`${msg.nickname}-joined-${index}`}>
                  <span>{msg.nickname} just joined.</span>
                </div>
              );
            } else if (msg.action === "user_left") {
              return (
                <div key={`${msg.nickname}-left-${index}`}>
                  <span>{msg.nickname} just left.</span>
                </div>
              );
            }
          })}
        </div>
        <div className="flex flex-row border-2 rounded-md border-gray-300 mt-auto p-2">
          <span className="border-r-2 border-gray-300 pr-2">{ws.username}</span>
          <input
            className="flex-1 pl-2 focus:outline-none bg-gray-50"
            onChange={(e) => setText(e.currentTarget.value)}
            onKeyUp={(e) => {
              if (e.key === "Enter") {
                onSubmit();
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
