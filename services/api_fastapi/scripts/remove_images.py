#!/usr/bin/env python3
"""Remove image references from research posts."""

import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("../secrets/firebase-service-account.json")
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("Removing image references from research posts...")

posts = db.collection("research_posts").stream()
count = 0

for post in posts:
    post_ref = db.collection("research_posts").document(post.id)
    post_ref.update({
        "image_url": None,
        "image_urls": []
    })
    count += 1
    print(f"[OK] Updated post: {post.to_dict().get('title')}")

print(f"\n[SUCCESS] Updated {count} posts - images removed")
