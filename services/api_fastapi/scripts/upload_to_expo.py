#!/usr/bin/env python3
"""Upload issues as research posts to Innovation Expo."""

import json
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("../secrets/firebase-service-account.json")
    firebase_admin.initialize_app(cred)
db = firestore.client()

# Read issues
with open("issues.local-images.json", "r", encoding="utf-8") as f:
    issues = json.load(f)

print(f"Converting {len(issues)} issues to research posts for Innovation Expo...")

for idx, issue in enumerate(issues, 1):
    # Convert issue to research post format
    local_paths = issue.get("local_image_paths", [])
    
    post_data = {
        "author_id": issue.get("reporter_id", "community_user"),
        "author_email": issue.get("reporter_name", "Local Resident") + "@community.local",
        "title": issue.get("title", ""),
        "abstract": issue.get("description", ""),
        "problem_solved": issue.get("caption", issue.get("description", "")),
        "image_url": local_paths[0] if local_paths else None,
        "image_urls": local_paths,
        "caption": issue.get("caption"),
        "sdg_tags": [],
        "funding_goal": 0.0,
        "funding_raised": 0.0,
        "likes": 0,
        "liked_by": [],
        "created_at": firestore.SERVER_TIMESTAMP,
    }
    
    # Upload to research_posts collection
    doc_ref = db.collection("research_posts").document()
    doc_ref.set(post_data)
    
    print(f"[OK] Uploaded post {idx}: {post_data['title']} (ID: {doc_ref.id})")

print(f"\n[SUCCESS] Successfully uploaded {len(issues)} posts to Innovation Expo!")
