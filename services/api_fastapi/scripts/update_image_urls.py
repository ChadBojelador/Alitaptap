#!/usr/bin/env python3
"""Update research posts with localhost image URLs."""

import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("../secrets/firebase-service-account.json")
    firebase_admin.initialize_app(cred)
db = firestore.client()

# Mapping of local paths to localhost URLs
image_mapping = {
    "images/1.jpg": "http://localhost:8000/images/1.jpg",
    "images/2.1.jpg": "http://localhost:8000/images/2.1.jpg",
    "images/2.jpg": "http://localhost:8000/images/2.jpg",
    "images/3.jpg": "http://localhost:8000/images/3.jpg",
}

print("Updating research posts with localhost image URLs...")

posts = db.collection("research_posts").stream()
count = 0

for post in posts:
    data = post.to_dict()
    local_image_urls = data.get("image_urls", [])
    
    # Convert local paths to localhost URLs
    new_image_urls = []
    for local_path in local_image_urls:
        if local_path in image_mapping:
            new_image_urls.append(image_mapping[local_path])
    
    if new_image_urls:
        post_ref = db.collection("research_posts").document(post.id)
        post_ref.update({
            "image_url": new_image_urls[0],
            "image_urls": new_image_urls
        })
        count += 1
        print(f"[OK] Updated post: {data.get('title')} with {len(new_image_urls)} image(s)")

print(f"\n[SUCCESS] Updated {count} posts with localhost image URLs")
print("Images will be served at: http://localhost:8000/images/")
