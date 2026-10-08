"""Deterministic external CMMS stand-in; no database or production access."""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

ORDERS = {
    "WO-1042": {
        "id": "WO-1042", "asset": "Mixer-7", "priority": "high",
        "summary": "Excess vibration on discharge bearing", "status": "open",
    },
    "WO-1043": {
        "id": "WO-1043", "asset": "Pump-2", "priority": "low",
        "summary": "Scheduled seal inspection", "status": "open",
    },
}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/health":
            self.respond(200, {"status": "ok"})
        elif path.startswith("/work-orders/"):
            order_id = path.rsplit("/", 1)[-1]
            order = ORDERS.get(order_id)
            self.respond(200 if order else 404, order or {"error": "not found"})
        else:
            self.respond(404, {"error": "not found"})

    def respond(self, status, body):
        payload = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8090), Handler).serve_forever()
