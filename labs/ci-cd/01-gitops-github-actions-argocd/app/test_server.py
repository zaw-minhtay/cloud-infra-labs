"""Tests for server.py. Run from the lab folder: python3 -m unittest discover -s app -v"""
import threading
import unittest
import urllib.error
import urllib.request
from http.server import HTTPServer

import server


class RenderPageTest(unittest.TestCase):
    def test_page_shows_message_and_version(self):
        page = server.render_page()
        self.assertIn(server.MESSAGE, page)
        self.assertIn(f"version={server.VERSION}", page)


class ServerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.httpd = HTTPServer(("127.0.0.1", 0), server.Handler)  # port 0 = any free port
        cls.port = cls.httpd.server_address[1]
        threading.Thread(target=cls.httpd.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.httpd.server_close()

    def get(self, path):
        return urllib.request.urlopen(f"http://127.0.0.1:{self.port}{path}", timeout=5)

    def test_root_returns_version(self):
        with self.get("/") as response:
            self.assertEqual(response.status, 200)
            self.assertIn("version=", response.read().decode())

    def test_healthz_returns_ok(self):
        with self.get("/healthz") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.read().decode(), "ok\n")

    def test_unknown_path_returns_404(self):
        with self.assertRaises(urllib.error.HTTPError) as error:
            self.get("/nope")
        self.assertEqual(error.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
