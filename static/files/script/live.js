const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

let broadcaster = null;
let viewers = [];

wss.on('connection', ws => {
  ws.on('message', message => {
    const data = JSON.parse(message);
    if (data.type === 'broadcaster') {
      broadcaster = ws;
      ws.isBroadcaster = true;
    } else if (data.type === 'viewer') {
      viewers.push(ws);
      ws.isViewer = true;
      if (broadcaster) broadcaster.send(JSON.stringify({ type: 'viewer' }));
    } else if (data.type === 'offer' && ws.isBroadcaster) {
      viewers.forEach(v => v.send(JSON.stringify({ type: 'offer', sdp: data.sdp })));
    } else if (data.type === 'answer' && ws.isViewer) {
      if (broadcaster) broadcaster.send(JSON.stringify({ type: 'answer', sdp: data.sdp }));
    } else if (data.type === 'candidate') {
      // ارسال candidate به طرف مقابل
      if (ws.isBroadcaster) {
        viewers.forEach(v => v.send(JSON.stringify({ type: 'candidate', candidate: data.candidate })));
      } else if (ws.isViewer && broadcaster) {
        broadcaster.send(JSON.stringify({ type: 'candidate', candidate: data.candidate }));
      }
    }
  });
  ws.on('close', () => {
    if (ws.isViewer) viewers = viewers.filter(v => v !== ws);
    if (ws.isBroadcaster) broadcaster = null;
  });
});