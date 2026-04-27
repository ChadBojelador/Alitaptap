"""
Quick CRUD test for MongoDB posts.
Starts the FastAPI server in a background thread, runs Create/Read/Update/Delete,
then prints a pass/fail summary.
"""
import sys
import time
import threading
import requests
import uvicorn
from app.main import app

BASE = "http://localhost:8765/api/v1"


def run_server():
    uvicorn.run(app, host="127.0.0.1", port=8765, log_level="error")


def wait_for_server(timeout=15):
    for _ in range(timeout * 2):
        try:
            r = requests.get(f"{BASE}/health", timeout=1)
            if r.status_code == 200:
                return True
        except Exception:
            pass
        time.sleep(0.5)
    return False


def check(label, condition, detail=""):
    status = "✅ PASS" if condition else "❌ FAIL"
    print(f"  {status}  {label}" + (f"  →  {detail}" if detail else ""))
    return condition


def main():
    print("\n🚀 Starting FastAPI server on port 8765...")
    t = threading.Thread(target=run_server, daemon=True)
    t.start()

    if not wait_for_server():
        print("❌ Server did not start in time.")
        sys.exit(1)
    print("✅ Server is up.\n")

    results = []

    # ── 1. Health / MongoDB connection ────────────────────────────────────────
    print("── 1. Health check ──────────────────────────────────────────────")
    r = requests.get(f"{BASE}/health")
    results.append(check("GET /health returns 200", r.status_code == 200, r.text[:120]))

    # ── 2. CREATE ─────────────────────────────────────────────────────────────
    print("\n── 2. CREATE post ───────────────────────────────────────────────")
    payload = {
        "author_id": "test-user-001",
        "author_email": "test@alitaptap.com",
        "title": "Solar-Powered Barangay Water Pump",
        "abstract": "A low-cost solar pump for off-grid communities.",
        "problem_solved": "Lack of clean water access in remote barangays.",
        "sdg_tags": ["SDG 6", "SDG 7"],
        "funding_goal": 50000.0,
    }
    r = requests.post(f"{BASE}/posts", json=payload)
    created = r.json() if r.status_code == 200 else {}
    post_id = created.get("post_id", "")
    results.append(check("POST /posts → 200", r.status_code == 200))
    results.append(check("Response has post_id", bool(post_id), post_id))
    results.append(check("Title matches", created.get("title") == payload["title"]))
    results.append(check("funding_raised starts at 0", created.get("funding_raised") == 0.0))
    print(f"  📄 Created post_id: {post_id}")

    if not post_id:
        print("\n⛔ Cannot continue without a post_id.")
        sys.exit(1)

    # ── 3. READ (list + single) ───────────────────────────────────────────────
    print("\n── 3. READ posts ────────────────────────────────────────────────")
    r = requests.get(f"{BASE}/posts")
    posts = r.json() if r.status_code == 200 else []
    results.append(check("GET /posts → 200", r.status_code == 200))
    results.append(check("List contains our post", any(p["post_id"] == post_id for p in posts)))

    r = requests.get(f"{BASE}/posts/{post_id}")
    single = r.json() if r.status_code == 200 else {}
    results.append(check("GET /posts/{id} → 200", r.status_code == 200))
    results.append(check("Single post title correct", single.get("title") == payload["title"]))

    # ── 4. UPDATE ─────────────────────────────────────────────────────────────
    print("\n── 4. UPDATE post ───────────────────────────────────────────────")
    update = {"title": "Solar Water Pump v2 (Updated)", "funding_goal": 75000.0}
    r = requests.put(f"{BASE}/posts/{post_id}", json=update)
    updated = r.json() if r.status_code == 200 else {}
    results.append(check("PUT /posts/{id} → 200", r.status_code == 200))
    results.append(check("Title updated", updated.get("title") == update["title"], updated.get("title")))
    results.append(check("Funding goal updated", updated.get("funding_goal") == 75000.0))

    # ── 5. DELETE ─────────────────────────────────────────────────────────────
    print("\n── 5. DELETE post ───────────────────────────────────────────────")
    r = requests.delete(f"{BASE}/posts/{post_id}")
    results.append(check("DELETE /posts/{id} → 200", r.status_code == 200))

    r = requests.get(f"{BASE}/posts/{post_id}")
    results.append(check("GET after delete → 404", r.status_code == 404))

    # ── Summary ───────────────────────────────────────────────────────────────
    passed = sum(results)
    total  = len(results)
    print(f"\n{'='*55}")
    print(f"  RESULT: {passed}/{total} checks passed")
    if passed == total:
        print("  🎉 All CRUD operations work correctly!")
    else:
        print(f"  ⚠️  {total - passed} check(s) failed.")
    print('='*55)
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
