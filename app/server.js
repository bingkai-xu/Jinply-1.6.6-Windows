'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

const port = Number(process.env.PORT) || 8787;
const htmlPath = path.join(__dirname, 'public', 'index.html');
const html = fs.readFileSync(htmlPath);

const server = http.createServer((req, res) => {
  const url = String(req.url || '/').split('?')[0];
  if (url === '/api/health') {
    res.writeHead(200, {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    });
    res.end('{"ok":true}');
    return;
  }
  res.writeHead(200, {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  res.end(html);
});

server.listen(port, '127.0.0.1', () => {
  console.log('Jinply is running at http://127.0.0.1:' + port);
});
