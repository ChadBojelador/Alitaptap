#!/usr/bin/env python3
"""Upload snake_problem_post.json (with images) to MongoDB via FastAPI.

Steps:
  1. Upload each image file via POST /posts/upload  → get back image_url
  2. Create the research post via POST /posts        → stored in MongoDB
"""

import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

BASE_URL = "http://127.0.0.1:8000/api/v1"
SCRIPT_DIR = Path(__file__).parent
JSON_FILE = SCRIPT_DIR / "snake_problem_post.json"


def upload_image(image_path: Path) -> str:
    """Multipart-upload an image; return the server-assigned URL."""
    url = f"{BASE_URL}/posts/upload"
    boundary = "----AlitaptapBoundary"
    filename = image_path.name
    mime = "image/jpeg" if filename.lower().endswith((".jpg", ".jpeg")) else "image/png"

    body_parts = [
        f"--{boundary}\r\n".encode(),
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode(),
        f"Content-Type: {mime}\r\n\r\n".encode(),
        image_path.read_bytes(),
        f"\r\n--{boundary}--\r\n".encode(),
    ]
    body = b"".join(body_parts)

    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read())
    return result["image_url"]


def create_post(payload: dict) -> dict:
    """POST the post payload; return the created post document."""
    url = f"{BASE_URL}/posts"
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def main() -> int:
    with JSON_FILE.open("r", encoding="utf-8") as f:
        posts = json.load(f)

    print(f"[INFO] Loaded {len(posts)} post(s) from {JSON_FILE.name}")

    for idx, post in enumerate(posts, start=1):
        title = post.get("title", f"Post #{idx}")
        print(f"\n[POST {idx}] {title}")

        # ── 1. Upload primary image ──────────────────────────────────────────
        image_url: str | None = None
        primary_path_str = post.pop("_image_file", None)
        if primary_path_str:
            primary_path = SCRIPT_DIR.parent / primary_path_str  # relative to api_fastapi/
            if not primary_path.exists():
                # try relative to scripts/ directly
                primary_path = SCRIPT_DIR / primary_path_str
            if primary_path.exists():
                print(f"  Uploading primary image: {primary_path.name} …")
                image_url = upload_image(primary_path)
                print(f"  → {image_url}")
            else:
                print(f"  [WARN] Primary image not found: {primary_path_str}")

        # ── 2. Upload extra images ───────────────────────────────────────────
        extra_image_urls: list[str] = []
        extra_paths = post.pop("_extra_images", []) or []
        for extra_str in extra_paths:
            extra_path = SCRIPT_DIR.parent / extra_str
            if not extra_path.exists():
                extra_path = SCRIPT_DIR / extra_str
            if extra_path.exists():
                print(f"  Uploading extra image:   {extra_path.name} …")
                url = upload_image(extra_path)
                extra_image_urls.append(url)
                print(f"  → {url}")
            else:
                print(f"  [WARN] Extra image not found: {extra_str}")

        # ── 3. Build & POST the post payload ─────────────────────────────────
        payload = {**post}
        if image_url:
            payload["image_url"] = image_url
        if extra_image_urls:
            payload["image_urls"] = extra_image_urls

        try:
            result = create_post(payload)
            print(f"  [OK] Created post ID: {result['post_id']}")
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            print(f"  [ERROR] HTTP {e.code}: {body}")
            return 1

    print("\n[SUCCESS] Snake problem post uploaded to MongoDB ✓")
    return 0


if __name__ == "__main__":
    sys.exit(main())
