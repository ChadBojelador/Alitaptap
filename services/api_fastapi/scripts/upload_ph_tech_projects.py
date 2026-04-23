#!/usr/bin/env python3
"""Upload Philippine tech research projects to Firestore."""

import json
import mimetypes
import time
import uuid
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage
from dotenv import load_dotenv

load_dotenv()

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("../secrets/firebase-service-account.json")
    firebase_admin.initialize_app(cred, {
        "storageBucket": "alitaptap-500c9.appspot.com"
    })
db = firestore.client()
bucket = storage.bucket()

def upload_image(file_path: Path, folder: str = "research-images") -> str:
    """Upload image to Firebase Storage and return public URL."""
    if not file_path.exists():
        print(f"[WARN] Image not found: {file_path}")
        return None
    
    stamp = int(time.time())
    unique = uuid.uuid4().hex[:10]
    blob_name = f"{folder}/{stamp}_{unique}_{file_path.name}"
    blob = bucket.blob(blob_name)
    
    content_type = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
    blob.upload_from_filename(str(file_path), content_type=content_type)
    blob.make_public()
    
    return blob.public_url

# Read tech projects
with open("ph_tech_projects.json", "r", encoding="utf-8") as f:
    projects = json.load(f)

print(f"Uploading {len(projects)} Philippine tech research projects to Innovation Expo...")

for idx, project in enumerate(projects, 1):
    # Handle image uploads
    image_urls = []
    local_paths = project.get("local_image_paths", [])
    
    if local_paths:
        print(f"  Uploading {len(local_paths)} images for project {idx}...")
        for local_path in local_paths:
            image_path = Path(local_path)
            if not image_path.is_absolute():
                image_path = Path(__file__).parent / local_path
            
            url = upload_image(image_path)
            if url:
                image_urls.append(url)
                print(f"    [OK] Uploaded: {image_path.name}")
    
    # Prepare research post data
    post_data = {
        "author_id": project.get("author_id", "researcher"),
        "author_email": project.get("author_email", "researcher@ph.edu"),
        "title": project.get("title", ""),
        "abstract": project.get("abstract", ""),
        "problem_solved": project.get("problem_solved", ""),
        "image_url": image_urls[0] if image_urls else None,
        "image_urls": image_urls,
        "caption": project.get("caption", ""),
        "sdg_tags": project.get("sdg_tags", []),
        "funding_goal": project.get("funding_goal", 0.0),
        "funding_raised": 0.0,
        "likes": 0,
        "liked_by": [],
        "created_at": firestore.SERVER_TIMESTAMP,
    }
    
    # Upload to research_posts collection
    doc_ref = db.collection("research_posts").document()
    doc_ref.set(post_data)
    
    print(f"[OK] Uploaded project {idx}: {post_data['title']} (ID: {doc_ref.id})")

print(f"\n[SUCCESS] Successfully uploaded {len(projects)} Philippine tech research projects!")
print("These projects are now visible in the Innovation Expo feed.")
