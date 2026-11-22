"""Demo web app for Lab 01: shows which version is running.

Uses only the Python standard library, so there is nothing to install.
  GET /         -> the message and the version (the Git commit SHA set by CI)
  GET /healthz  -> "ok" (used by the Kubernetes readiness and liveness probes)
"""
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

MESSAGE = "Hello from GitOps v2!"
VERSION = os.environ.get("APP_VERSION", "dev")


def render_page():
    return f"{MESSAGE} version={VERSION}\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self._send(200, render_page())
        elif self.path == "/healthz":
            self._send(200, "ok\n")
        else:
            self._send(404, "not found\n")

    def _send(self, status, body):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    print(f"Listening on port {port}, version={VERSION}", flush=True)
    HTTPServer(("", port), Handler).serve_forever()
