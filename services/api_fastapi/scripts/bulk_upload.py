#!/usr/bin/env python3
"""Bulk uploader for Alitaptap FastAPI endpoints.

Uploads issues and research posts using the API so server-side validation/enrichment
still runs. Supports retries and writes failed rows to JSON for easy re-run.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


def _read_json_array(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError(f"Expected a JSON array in {path}")

    rows: list[dict[str, Any]] = []
    for i, item in enumerate(data, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"Item #{i} in {path} is not a JSON object")
        rows.append(item)
    return rows


def _post_json(url: str, payload: dict[str, Any], timeout: float) -> tuple[int, str]:
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        text = e.read().decode("utf-8", errors="replace")
        return e.code, text


def _upload_rows(
    rows: list[dict[str, Any]],
    endpoint_url: str,
    kind: str,
    retries: int,
    timeout: float,
    pause_ms: int,
) -> tuple[int, list[dict[str, Any]]]:
    total = len(rows)
    success = 0
    failed: list[dict[str, Any]] = []

    if total == 0:
        print(f"[INFO] No {kind} rows to upload")
        return success, failed

    print(f"[INFO] Uploading {total} {kind} row(s) to {endpoint_url}")

    for idx, row in enumerate(rows, start=1):
        attempt = 0
        last_status = 0
        last_body = ""

        while attempt <= retries:
            attempt += 1
            status, body = _post_json(endpoint_url, row, timeout)
            last_status, last_body = status, body
            if 200 <= status < 300:
                success += 1
                break

            if attempt <= retries:
                backoff = min(2 ** (attempt - 1), 8)
                time.sleep(backoff)

        if not (200 <= last_status < 300):
            failed.append(
                {
                    "index": idx,
                    "status": last_status,
                    "response": last_body,
                    "payload": row,
                }
            )

        if idx % 10 == 0 or idx == total:
            print(
                f"[PROGRESS] {kind}: {idx}/{total} processed, "
                f"{success} success, {len(failed)} failed"
            )

        if pause_ms > 0:
            time.sleep(pause_ms / 1000.0)

    return success, failed


def _write_failures(path: Path, failures: dict[str, list[dict[str, Any]]]) -> None:
    payload = {
        "generated_at_unix": int(time.time()),
        "failures": failures,
    }
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
    print(f"[INFO] Wrote failed records to {path}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Bulk upload issues and projects (research posts) via FastAPI"
    )
    parser.add_argument(
        "--base-url",
        default="http://127.0.0.1:8000/api/v1",
        help="Base API URL (default: http://127.0.0.1:8000/api/v1)",
    )
    parser.add_argument(
        "--issues-file",
        type=Path,
        default=None,
        help="Path to issues JSON array file",
    )
    parser.add_argument(
        "--projects-file",
        type=Path,
        default=None,
        help="Path to projects JSON array file (uploads to /posts)",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=2,
        help="Retries per failed row (default: 2)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=20.0,
        help="HTTP timeout in seconds (default: 20)",
    )
    parser.add_argument(
        "--pause-ms",
        type=int,
        default=0,
        help="Optional pause between rows in milliseconds",
    )
    parser.add_argument(
        "--failed-out",
        type=Path,
        default=Path("bulk_upload_failed.json"),
        help="Output file for failed records",
    )

    args = parser.parse_args()

    if args.issues_file is None and args.projects_file is None:
        print("[ERROR] Provide at least one of --issues-file or --projects-file")
        return 2

    base_url = args.base_url.rstrip("/")

    failures: dict[str, list[dict[str, Any]]] = {"issues": [], "projects": []}
    uploaded_counts = {"issues": 0, "projects": 0}

    try:
        if args.issues_file is not None:
            issues = _read_json_array(args.issues_file)
            ok, failed = _upload_rows(
                rows=issues,
                endpoint_url=f"{base_url}/issues",
                kind="issues",
                retries=max(args.retries, 0),
                timeout=args.timeout,
                pause_ms=max(args.pause_ms, 0),
            )
            uploaded_counts["issues"] = ok
            failures["issues"] = failed

        if args.projects_file is not None:
            projects = _read_json_array(args.projects_file)
            ok, failed = _upload_rows(
                rows=projects,
                endpoint_url=f"{base_url}/posts",
                kind="projects",
                retries=max(args.retries, 0),
                timeout=args.timeout,
                pause_ms=max(args.pause_ms, 0),
            )
            uploaded_counts["projects"] = ok
            failures["projects"] = failed

    except (FileNotFoundError, ValueError, json.JSONDecodeError) as e:
        print(f"[ERROR] {e}")
        return 2
    except urllib.error.URLError as e:
        print(f"[ERROR] Network error: {e}")
        return 3

    issue_fail = len(failures["issues"])
    project_fail = len(failures["projects"])

    print("\n[SUMMARY]")
    print(
        "issues: "
        f"{uploaded_counts['issues']} uploaded, {issue_fail} failed"
    )
    print(
        "projects: "
        f"{uploaded_counts['projects']} uploaded, {project_fail} failed"
    )

    if issue_fail > 0 or project_fail > 0:
        _write_failures(args.failed_out, failures)
        return 1

    print("[INFO] Bulk upload completed with no failures")
    return 0


if __name__ == "__main__":
    sys.exit(main())
