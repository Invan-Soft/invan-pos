"""Server yiqilishini taqlid qiluvchi eng oddiy server.

Ishlatish:
    python3 tool/fake_server.py 500     # hamma so'rovga 500
    python3 tool/fake_server.py hang    # javob bermaydi (osilib qoladi)
    python3 tool/fake_server.py ok      # normal ishlaydi (tiklandi)

Kassa manzili shu paytda `http://localhost:8000/` ga qaratilgan bo'lishi kerak
(api_provider.dart). HTTPS emas — shuning uchun sertifikat kerak emas.
"""
import sys, time
from http.server import BaseHTTPRequestHandler, HTTPServer

MODE = sys.argv[1] if len(sys.argv) > 1 else "500"


class Handler(BaseHTTPRequestHandler):
    def _handle(self):
        length = int(self.headers.get('Content-Length') or 0)
        if length:
            self.rfile.read(length)
        print(f"  → {self.command} {self.path}  [rejim: {MODE}]", flush=True)

        if MODE == "hang":
            time.sleep(600)          # javob bermaymiz
            return
        if MODE == "ok":
            body = b'{"message":"Success","data":[],"employees":[]}'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_error(500, "Internal Server Error")

    do_GET = do_POST = do_PUT = do_DELETE = do_PATCH = _handle

    def log_message(self, *args):
        pass


print(f"Soxta server: http://localhost:8000/  rejim = {MODE}")
HTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
