// Mountain Goats — WebSocket relay server.
// Routes JSON messages between two players sharing a room code.
// No game logic — just forwarding.
//
// Usage: node relay.js [port]  (default port: 8765)

const WebSocket = require("ws");

const PORT = parseInt(process.argv[2] || process.env.PORT || "8765", 10);
const server = new WebSocket.Server({ port: PORT });

// rooms: Map<code, [ws, ws?]>
const rooms = new Map();

function generateCode() {
  const n = Math.floor(Math.random() * 9000) + 1000;
  return `GOAT-${n}`;
}

function send(ws, data) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

function findRoomBySocket(ws) {
  for (const [code, members] of rooms) {
    if (members.includes(ws)) return code;
  }
  return null;
}

server.on("connection", (ws) => {
  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      return;
    }

    switch (msg.type) {
      case "create_room": {
        // Generate unique code
        let code;
        do { code = generateCode(); } while (rooms.has(code));
        rooms.set(code, [ws]);
        send(ws, { type: "room_created", code });
        break;
      }

      case "join_room": {
        const code = msg.code;
        const members = rooms.get(code);
        if (!members || members.length !== 1) {
          send(ws, { type: "error", message: "Room not found or already full." });
          return;
        }
        members.push(ws);
        send(members[0], { type: "opponent_connected" });
        send(members[1], { type: "opponent_connected" });
        break;
      }

      case "relay": {
        const code = findRoomBySocket(ws);
        if (!code) return;
        const members = rooms.get(code);
        for (const other of members) {
          if (other !== ws) send(other, { type: "relay", data: msg.data });
        }
        break;
      }
    }
  });

  ws.on("close", () => {
    const code = findRoomBySocket(ws);
    if (!code) return;
    const members = rooms.get(code);
    for (const other of members) {
      if (other !== ws) send(other, { type: "opponent_disconnected" });
    }
    rooms.delete(code);
  });
});

console.log(`Mountain Goats relay server running on ws://localhost:${PORT}`);
