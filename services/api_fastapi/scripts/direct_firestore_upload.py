#!/usr/bin/env python3
"""Direct upload to Firestore without images."""

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
    # Remove local image paths since we can't upload them yet
    issue.pop("local_image_paths", None)
    
    # Add default fields
    issue["status"] = "pending"
    issue["upvotes"] = 0
    issue["downvotes"] = 0
    issue["created_at"] = firestore.SERVER_TIMESTAMP
    issue["updated_at"] = firestore.SERVER_TIMESTAMP
    
    # Upload to Firestore
    doc_ref = db.collection("issues").document()
    doc_ref.set(issue)
    
    print(f"✓ Uploaded issue {idx}: {issue['title']} (ID: {doc_ref.id})")

print(f"\n✅ Successfully uploaded {len(issues)} issues to Firestore!")
