# serve_web.py — server web build cho auto-test, LUÔN gửi no-store để
# trình duyệt không ăn cache index.pck cũ sau mỗi lần rebuild.
# Chạy:  python tools/serve_web.py [port]   (mặc định 8094, serve từ build/web)
import http.server
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8094
ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "build", "web")


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, must-revalidate")
        super().end_headers()


if __name__ == "__main__":
    os.chdir(ROOT)
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), NoCacheHandler).serve_forever()
