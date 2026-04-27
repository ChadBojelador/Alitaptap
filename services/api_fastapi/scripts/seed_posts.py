#!/usr/bin/env python3
"""Seed research posts into MongoDB via the FastAPI endpoints.

Two-step flow for each post:
  1. If '_image_file' key is present, upload the image to POST /posts/upload
     and replace '_image_file' with the returned 'image_url'.
  2. POST the cleaned payload to POST /posts.

Usage:
    python scripts/seed_posts.py --file scripts/my_posts.json
    python scripts/seed_posts.py --file scripts/my_posts.json --base-url http://10.0.2.2:8000/api/v1
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


BASE_URL = "http://127.0.0.1:8000/api/v1"


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def _post_json(url: str, payload: dict[str, Any]) -> tuple[int, dict]:
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        text = e.read().decode("utf-8", errors="replace")
        print(f"    [HTTP {e.code}] {text}")
        return e.code, {}


def _upload_image(upload_url: str, image_path: Path) -> str | None:
    """Upload a local image file using multipart/form-data.
    Returns the remote image_url string, or None on failure.
    """
    boundary = "----AlitaptapBoundary7MA4YWxkTrZu0gW"
    filename = image_path.name
    ext = image_path.suffix.lower()

    mime_types = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".webp": "image/webp",
    }
    content_type = mime_types.get(ext, "application/octet-stream")

    try:
        with open(image_path, "rb") as f:
            file_data = f.read()
    except FileNotFoundError:
        print(f"    [WARN] Image not found: {image_path}")
        return None

    # Build multipart body manually (no external dependencies)
    body_parts = [
        f"--{boundary}\r\n".encode(),
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode(),
        f"Content-Type: {content_type}\r\n\r\n".encode(),
        file_data,
        f"\r\n--{boundary}--\r\n".encode(),
    ]
    body = b"".join(body_parts)

    req = urllib.request.Request(
        upload_url,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read())
            url = result.get("image_url")
            if url:
                print(f"    [IMG] Uploaded → {url}")
            return url
    except urllib.error.HTTPError as e:
        text = e.read().decode("utf-8", errors="replace")
        print(f"    [IMG ERROR {e.code}] {text}")
        return None


# ---------------------------------------------------------------------------
# Main seed logic
# ---------------------------------------------------------------------------

def seed(posts_file: Path, base_url: str) -> int:
    base_url = base_url.rstrip("/")
    upload_url = f"{base_url}/posts/upload"
    posts_url = f"{base_url}/posts"

    if not posts_file.exists():
        print(f"[ERROR] File not found: {posts_file}")
        return 1

    with posts_file.open("r", encoding="utf-8") as f:
        posts: list[dict] = json.load(f)

    if not isinstance(posts, list):
        print("[ERROR] JSON file must contain an array of post objects.")
        return 1

    print(f"[INFO] Seeding {len(posts)} post(s) from {posts_file.name}\n")

    success = 0
    failed = 0

    for idx, post in enumerate(posts, start=1):
        print(f"[{idx}/{len(posts)}] {post.get('title', '(no title)')}")

        # --- Step 1: upload images (_image_file = primary, _extra_images = additional) ---
        image_file_raw: str | None = post.pop("_image_file", None)
        extra_images_raw: list[str] = post.pop("_extra_images", [])

        all_local_images: list[str] = []
        if image_file_raw:
            all_local_images.append(image_file_raw)
        all_local_images.extend(extra_images_raw)

        uploaded_urls: list[str] = []
        for img_raw in all_local_images:
            image_path = Path(img_raw)
            if not image_path.is_absolute():
                candidate = posts_file.parent / img_raw
                image_path = candidate if candidate.exists() else Path(__file__).parent / img_raw
            url = _upload_image(upload_url, image_path)
            if url:
                uploaded_urls.append(url)

        if uploaded_urls:
            post["image_url"] = uploaded_urls[0]
            post.setdefault("image_urls", [])
            for url in uploaded_urls:
                if url not in post["image_urls"]:
                    post["image_urls"].append(url)

        # --- Step 2: post to /posts ---
        status, body = _post_json(posts_url, post)
        if 200 <= status < 300:
            print(f"    [OK] Created post_id={body.get('post_id', '?')}")
            success += 1
        else:
            print(f"    [FAIL] HTTP {status}")
            failed += 1

        print()

    print(f"[SUMMARY] {success} succeeded, {failed} failed out of {len(posts)} posts")
    return 0 if failed == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed research posts (with optional images) into MongoDB via the FastAPI."
    )
    parser.add_argument(
        "--file",
        type=Path,
        required=True,
        help="Path to a JSON array of post objects. Use '_image_file' key for local image paths.",
    )
    parser.add_argument(
        "--base-url",
        default=BASE_URL,
        help=f"Base API URL (default: {BASE_URL})",
    )
    args = parser.parse_args()
    return seed(args.file, args.base_url)


if __name__ == "__main__":
    sys.exit(main())
