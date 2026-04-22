#!/usr/bin/env python3
"""Upload local issue images to Firebase Storage and write image URLs back to JSON.

Input JSON is expected to be an array of issue objects.
Each issue may include any of these helper fields:
- local_image_path
- image_path
- local_image_paths (array)
- image_paths (array)

The script uploads local files to Firebase Storage and writes:
- image_urls (array)
- image_url (first image, for backward compatibility)

Helper fields are removed in output JSON.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import time
import uuid
from pathlib import Path
from typing import Any

import firebase_admin
from dotenv import load_dotenv
from firebase_admin import credentials, storage


def _read_json_array(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise FileNotFoundError(f"Issues file not found: {path}")

    with path.open("r", encoding="utf-8") as f:
        payload = json.load(f)

    if not isinstance(payload, list):
        raise ValueError(f"Expected a JSON array in {path}")

    rows: list[dict[str, Any]] = []
    for idx, item in enumerate(payload, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"Item #{idx} in {path} is not a JSON object")
        rows.append(item)

    return rows


def _resolve_image_path(raw_path: str, images_root: Path | None) -> Path:
    p = Path(raw_path)
    if p.is_absolute():
        return p
    if images_root is not None:
        return (images_root / p).resolve()
    return p.resolve()


def _collect_local_paths(item: dict[str, Any]) -> list[str]:
    single = item.get("local_image_path") or item.get("image_path")
    many = item.get("local_image_paths") or item.get("image_paths") or []

    collected: list[str] = []
    if single:
        collected.append(str(single))
    if isinstance(many, list):
        for p in many:
            if p:
                collected.append(str(p))

    # Keep order while removing duplicates.
    seen: set[str] = set()
    unique: list[str] = []
    for p in collected:
        if p in seen:
            continue
        seen.add(p)
        unique.append(p)
    return unique


def _build_blob_name(folder: str, file_path: Path) -> str:
    safe_folder = folder.strip("/") or "issue-images"
    stamp = int(time.time())
    unique = uuid.uuid4().hex[:10]
    return f"{safe_folder}/{stamp}_{unique}_{file_path.name}"


def _init_storage_app(service_account_path: str, bucket_name: str) -> None:
    if firebase_admin._apps:
        return

    if service_account_path:
        if not Path(service_account_path).exists():
            raise FileNotFoundError(
                f"Service account JSON not found: {service_account_path}"
            )
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred, {"storageBucket": bucket_name})
        return

    firebase_admin.initialize_app(options={"storageBucket": bucket_name})


def _upload_file(
    bucket: storage.bucket,
    file_path: Path,
    folder: str,
    make_public: bool,
) -> str:
    blob_name = _build_blob_name(folder, file_path)
    blob = bucket.blob(blob_name)

    content_type = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
    blob.upload_from_filename(str(file_path), content_type=content_type)

    if make_public:
        blob.make_public()
        return blob.public_url

    # Private object fallback URL format (may require auth depending on rules).
    return (
        f"https://storage.googleapis.com/{bucket.name}/{blob_name}"
    )


def main() -> int:
    load_dotenv()

    parser = argparse.ArgumentParser(
        description="Upload local issue images to Firebase Storage and fill image_url/image_urls"
    )
    parser.add_argument(
        "--issues-file",
        type=Path,
        required=True,
        help="Input issues JSON file",
    )
    parser.add_argument(
        "--output-file",
        type=Path,
        default=Path("issues.with_image_urls.json"),
        help="Output JSON with image_url and image_urls fields filled",
    )
    parser.add_argument(
        "--images-root",
        type=Path,
        default=None,
        help="Base folder for relative local image paths",
    )
    parser.add_argument(
        "--service-account",
        default=os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", ""),
        help="Path to Firebase service account JSON (defaults to FIREBASE_SERVICE_ACCOUNT_PATH)",
    )
    parser.add_argument(
        "--project-id",
        default=os.getenv("FIREBASE_PROJECT_ID", ""),
        help="Firebase project ID (defaults to FIREBASE_PROJECT_ID)",
    )
    parser.add_argument(
        "--bucket",
        default=os.getenv("FIREBASE_STORAGE_BUCKET", ""),
        help="Firebase storage bucket name (defaults to FIREBASE_STORAGE_BUCKET)",
    )
    parser.add_argument(
        "--folder",
        default="issue-images",
        help="Storage folder prefix (default: issue-images)",
    )
    parser.add_argument(
        "--make-public",
        action="store_true",
        help="Make uploaded objects public and use public URL",
    )

    args = parser.parse_args()

    try:
        issues = _read_json_array(args.issues_file)
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as e:
        print(f"[ERROR] {e}")
        return 2

    project_id = args.project_id.strip()
    bucket_name = args.bucket.strip()
    if not bucket_name:
        if not project_id:
            print("[ERROR] Provide --bucket or set FIREBASE_STORAGE_BUCKET (or project id for fallback)")
            return 2
        bucket_name = f"{project_id}.appspot.com"

    try:
        _init_storage_app(args.service_account.strip(), bucket_name)
        bucket = storage.bucket(bucket_name)
    except Exception as e:  # noqa: BLE001
        print(f"[ERROR] Firebase init failed: {e}")
        return 3

    total = len(issues)
    uploaded = 0
    skipped = 0
    failed = 0

    out_rows: list[dict[str, Any]] = []

    for idx, row in enumerate(issues, start=1):
        item = dict(row)
        raw_image_paths = _collect_local_paths(item)

        # Remove helper fields from output payload.
        item.pop("local_image_path", None)
        item.pop("image_path", None)
        item.pop("local_image_paths", None)
        item.pop("image_paths", None)

        if not raw_image_paths:
            # Preserve existing URL values if already set.
            existing_urls = item.get("image_urls") or []
            existing_cover = item.get("image_url")
            if existing_cover and existing_cover not in existing_urls:
                item["image_urls"] = [existing_cover, *existing_urls]
            elif existing_urls:
                item["image_url"] = existing_cover or existing_urls[0]
            skipped += 1
            out_rows.append(item)
            continue

        urls_for_row: list[str] = []
        row_has_failure = False
        for raw_path in raw_image_paths:
            image_path = _resolve_image_path(raw_path, args.images_root)
            if not image_path.exists():
                row_has_failure = True
                print(f"[WARN] Row {idx}: image not found: {image_path}")
                continue

            try:
                url = _upload_file(
                    bucket=bucket,
                    file_path=image_path,
                    folder=args.folder,
                    make_public=args.make_public,
                )
                urls_for_row.append(url)
                uploaded += 1
            except Exception as e:  # noqa: BLE001
                row_has_failure = True
                print(f"[WARN] Row {idx}: upload failed for {image_path}: {e}")

        if urls_for_row:
            item["image_urls"] = urls_for_row
            item["image_url"] = urls_for_row[0]

        if row_has_failure:
            failed += 1

        out_rows.append(item)

        if idx % 10 == 0 or idx == total:
            print(
                f"[PROGRESS] {idx}/{total} rows, "
                f"uploaded={uploaded}, skipped={skipped}, failed={failed}"
            )

    args.output_file.parent.mkdir(parents=True, exist_ok=True)
    with args.output_file.open("w", encoding="utf-8") as f:
        json.dump(out_rows, f, indent=2, ensure_ascii=False)

    print("\n[SUMMARY]")
    print(f"bucket: {bucket_name}")
    print(f"rows total: {total}")
    print(f"rows uploaded: {uploaded}")
    print(f"rows skipped: {skipped}")
    print(f"rows failed: {failed}")
    print(f"output: {args.output_file}")

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
