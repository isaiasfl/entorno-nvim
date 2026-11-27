#!/usr/bin/env python3
"""Prueba aislada de scripts/ejecutar-http.py contra un servidor HTTP local."""
import json
import os
import subprocess
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts" / "ejecutar-http.py"


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        auth = self.headers.get("Authorization", "")
        payload = json.dumps({"ok": True, "path": self.path, "auth": auth}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = json.loads(self.rfile.read(length).decode("utf-8"))
        payload = json.dumps({"created": body.get("title"), "rating": body.get("rating")}).encode()
        self.send_response(201)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def main():
    server = HTTPServer(("127.0.0.1", 0), Handler)
    port = server.server_address[1]
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    try:
        with tempfile.TemporaryDirectory() as tmp:
            http_file = Path(tmp) / "api.http"
            http_file.write_text(
                f"@baseUrl = http://127.0.0.1:{port}\n"
                "\n"
                "### Listar peliculas\n"
                "GET {{baseUrl}}/api/movies\n"
                "Authorization: Bearer {{$env.TEST_HTTP_TOKEN}}\n"
                "\n"
                "### Crear pelicula\n"
                "POST {{baseUrl}}/api/movies\n"
                "Content-Type: application/json\n"
                "\n"
                '{"title": "Matrix", "rating": 9}\n',
                encoding="utf-8",
            )

            env = dict(os.environ, TEST_HTTP_TOKEN="secreto-demo")

            # Bloque 1: GET (linea 4)
            r1 = subprocess.run(
                ["python3", str(SCRIPT), str(http_file), "4"],
                capture_output=True, text=True, env=env, check=True,
            )
            assert "HTTP 200" in r1.stdout, r1.stdout
            assert '"auth": "Bearer secreto-demo"' in r1.stdout, r1.stdout
            assert '"path": "/api/movies"' in r1.stdout, r1.stdout

            # Bloque 2: POST (linea 8)
            r2 = subprocess.run(
                ["python3", str(SCRIPT), str(http_file), "8"],
                capture_output=True, text=True, env=env, check=True,
            )
            assert "HTTP 201" in r2.stdout, r2.stdout
            assert '"created": "Matrix"' in r2.stdout, r2.stdout
            assert '"rating": 9' in r2.stdout, r2.stdout
    finally:
        server.shutdown()

    print("OK: ejecutar-http.py (variables, $env, bloques ###, GET/POST y JSON formateado)")


if __name__ == "__main__":
    main()
