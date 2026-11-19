import glob
import html
import mimetypes
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

NAME = os.environ.get("STUDENT_NAME", "[ชื่อ]")
SID = os.environ.get("STUDENT_ID", "[รหัสนักศึกษา]")
PHOTO_GLOB = os.environ.get("PHOTO_GLOB", "/photo/photo.*")
PORT = int(os.environ.get("PORT", "8080"))

PAGE = """<!doctype html>
<html lang="th"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>About</title>
<style>
 body{{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
      font-family:system-ui,-apple-system,"Sarabun",sans-serif;background:#f4f6fb;color:#14213d}}
 .card{{background:#fff;padding:2rem 3rem;border-radius:1rem;text-align:center;
       box-shadow:0 4px 24px rgba(0,0,0,.1)}}
 img{{width:220px;height:220px;object-fit:cover;border-radius:50%;border:4px solid #14213d}}
 h1{{margin:1rem 0 .25rem}} p{{margin:.25rem 0;font-size:1.25rem}}
 small{{color:#777}}
</style></head><body><div class="card">
<img src="/about/photo" alt="photo">
<h1>{name}</h1>
<p>ID: {sid}</p>
<small>served by app-about &middot; pod {pod}</small>
</div></body></html>"""


def find_photo():
    files = sorted(glob.glob(PHOTO_GLOB))
    return files[0] if files else None


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0].rstrip("/") or "/"
        if path == "/healthz":
            return self._send(200, b"ok", "text/plain")
        if path == "/about":
            body = PAGE.format(
                name=html.escape(NAME),
                sid=html.escape(SID),
                pod=html.escape(os.environ.get("HOSTNAME", "?")),
            ).encode()
            return self._send(200, body, "text/html; charset=utf-8")
        if path == "/about/photo":
            photo = find_photo()
            if not photo:
                return self._send(404, b"no photo", "text/plain")
            ctype = mimetypes.guess_type(photo)[0] or "application/octet-stream"
            with open(photo, "rb") as f:
                return self._send(200, f.read(), ctype)
        self._send(404, b"not found", "text/plain")


if __name__ == "__main__":
    print(f"app-about listening on :{PORT}", flush=True)
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()
