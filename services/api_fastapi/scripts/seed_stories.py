"""Seed the stories collection with the original 4 story posts."""

import requests

BASE_URL = "http://127.0.0.1:8000/api/v1"

STORIES = [
    {
        "bubble_label": "Soap",
        "title": "Soap Project Story",
        "description": "A hygiene-focused student project that explores low-cost soap solutions for households and community sanitation.",
        "sdg_label": "SDG 3",
        "sdg_name": "Good Health and Well-being",
        "image_url": None,
    },
    {
        "bubble_label": "Shredder",
        "title": "Paper Shredder Story",
        "description": "A paper recycling and shredding initiative that helps reduce paper waste and encourages responsible material reuse.",
        "sdg_label": "SDG 12",
        "sdg_name": "Responsible Consumption and Production",
        "image_url": None,
    },
    {
        "bubble_label": "Monitoring",
        "title": "Monitoring System Story",
        "description": "A community monitoring setup designed to improve local issue tracking and support faster barangay response workflows.",
        "sdg_label": "SDG 11",
        "sdg_name": "Sustainable Cities and Communities",
        "image_url": None,
    },
    {
        "bubble_label": "Earthquake",
        "title": "Earthquake System Story",
        "description": "An early-warning concept for earthquake preparedness that supports safer schools and community evacuation readiness.",
        "sdg_label": "SDG 11",
        "sdg_name": "Sustainable Cities and Communities",
        "image_url": None,
    },
]


def seed():
    # Check existing stories to avoid duplicates
    res = requests.get(f"{BASE_URL}/stories")
    existing_titles = {s["title"] for s in res.json()} if res.status_code == 200 else set()

    inserted = 0
    for story in STORIES:
        if story["title"] in existing_titles:
            print(f"  skip (already exists): {story['title']}")
            continue
        r = requests.post(f"{BASE_URL}/stories", json=story)
        if r.status_code == 200:
            print(f"  inserted: {story['title']}")
            inserted += 1
        else:
            print(f"  FAILED ({r.status_code}): {story['title']} — {r.text}")

    print(f"\nDone. {inserted} stories inserted.")


if __name__ == "__main__":
    seed()
