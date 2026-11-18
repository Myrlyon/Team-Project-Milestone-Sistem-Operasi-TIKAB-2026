#!/usr/bin/env python3

import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("APP_PORT", "8000"))


def db_reachable():
    try:
        with socket.create_connection(("127.0.0.1", 3306), timeout=2):
            return True
    except OSError:
        return False


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = {
                "status": "ok",
                "db": "up" if db_reachable() else "down",
                "client_ip": self.headers.get("X-Real-IP", self.client_address[0]),
            }
        else:
            body = {
                "service": "webapp",
                "message": "Multi-tier app is running",
            }

        data = json.dumps(body).encode()

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
