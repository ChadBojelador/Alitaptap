#!/usr/bin/env python3
"""Direct upload to Firestore with image filenames."""

import json
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

# Initialize Firebase
cred = credentials.Certificate("../secrets/firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Read issues
with open("issues.local-images.json", "r", encoding="utf-8") as f:
    issues = json.load(f)

print(f"Uploading {len(issues)} issues to Firestore...")

for idx, issue in enumerate(issues, 1):
    # Convert local_image_paths to image_urls (keeping filenames)
    local_paths = issue.pop("local_image_paths", [])
    if local_paths:
        issue["image_urls"] = local_paths
        issue["image_url"] = local_paths[0]
    
    # Add default fields
    issue["status"] = "pending"
    issue["upvotes"] = 0
    issue["downvotes"] = 0
    issue["created_at"] = firestore.SERVER_TIMESTAMP
    issue["updated_at"] = firestore.SERVER_TIMESTAMP
    
    # Upload to Firestore
    doc_ref = db.collection("issues").document()
    doc_ref.set(issue)
    
    print(f"[OK] Uploaded issue {idx}: {issue['title']} (ID: {doc_ref.id})")

print(f"\n[SUCCESS] Successfully uploaded {len(issues)} issues to Firestore!")
print("Note: Images are stored as filenames. You can host them separately or use a free hosting service.")
