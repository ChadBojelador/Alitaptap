#!/usr/bin/env python3
"""Update research posts with newly added images."""

import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("../secrets/firebase-service-account.json")
    firebase_admin.initialize_app(cred)
db = firestore.client()

# Mapping of project titles to image filenames (checking what exists)
image_mapping = {
    "Electric Jeepney Modernization Program": "electric jeep.jpg",
    "Coco Coir: Sustainable Growing Medium from Coconut Waste": "coconut coir.jpg",
    "Doppler Weather Radar Network for Typhoon Tracking": "doppler.jpg",
}

print("Updating research posts with newly added images...\n")

# Get all research posts
posts = db.collection("research_posts").stream()

updated = 0
for post in posts:
    data = post.to_dict()
    title = data.get("title", "")
    
    # Check if this post needs an image update
    if title in image_mapping:
        filename = image_mapping[title]
        image_path = Path("images") / filename
        
        if image_path.exists():
            image_url = f"http://localhost:8000/images/{filename}"
            
            # Update the post with image URL
            post_ref = db.collection("research_posts").document(post.id)
            post_ref.update({
                "image_url": image_url,
                "image_urls": [image_url]
            })
            
            print(f"[OK] Updated: {title}")
            print(f"     Image: {filename}")
            updated += 1
        else:
            print(f"[WARN] Image not found: {filename}")
    
print(f"\n[SUCCESS] Updated {updated} posts with images!")
print("Refresh your Innovation Expo to see the images.")
