#!/usr/bin/env python3
"""Upload real Philippine research projects with images to Firestore."""

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

# Image mapping for each project
image_mapping = {
    "Golden Rice: Vitamin A-Enriched Rice for Filipino Children": "http://localhost:8000/images/golden-rice.jpg",
    "Electric Jeepney Modernization Program": "http://localhost:8000/images/e-jeepney.jpg",
    "Coco Coir: Sustainable Growing Medium from Coconut Waste": "http://localhost:8000/images/coco-coir.jpg",
    "Doppler Weather Radar Network for Typhoon Tracking": "http://localhost:8000/images/doppler-radar.jpg",
    "Pinoy Nutribun: Fortified Bread for School Feeding Programs": "http://localhost:8000/images/nutribun.jpg",
    "Earthquake Early Warning System for Metro Manila": "http://localhost:8000/images/earthquake-sensor.jpg",
    "Bamboo as Sustainable Construction Material": "http://localhost:8000/images/bamboo-construction.jpg",
    "Virgin Coconut Oil: Health Benefits and Production Technology": "http://localhost:8000/images/vco-production.jpg",
    "Coral Reef Restoration in Philippine Waters": "http://localhost:8000/images/coral-restoration.jpg",
    "Climate-Resilient Rice Varieties for Philippine Farmers": "http://localhost:8000/images/rice-research.jpg",
}

# Read research projects
with open("real_ph_research_projects.json", "r", encoding="utf-8") as f:
    projects = json.load(f)

print(f"Uploading {len(projects)} real Philippine research projects to Innovation Expo...\n")

uploaded = 0
skipped = 0

for idx, project in enumerate(projects, 1):
    title = project.get("title", "")
    
    # Check if image exists
    image_url = image_mapping.get(title)
    image_exists = False
    if image_url:
        # Extract filename from URL
        filename = image_url.split("/")[-1]
        image_path = Path("images") / filename
        image_exists = image_path.exists()
    
    # Prepare research post data
    post_data = {
        "author_id": project.get("author_id", "researcher"),
        "author_email": project.get("author_email", "researcher@ph.edu"),
        "title": title,
        "abstract": project.get("abstract", ""),
        "problem_solved": project.get("problem_solved", ""),
        "image_url": image_url if image_exists else None,
        "image_urls": [image_url] if image_exists else [],
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
    
    if image_exists:
        print(f"[OK] Uploaded project {idx}: {title}")
        print(f"     Image: {filename}")
        uploaded += 1
    else:
        print(f"[WARN] Uploaded project {idx}: {title}")
        print(f"       Missing image: {image_url.split('/')[-1] if image_url else 'N/A'}")
        skipped += 1
    print()

print(f"\n[SUMMARY]")
print(f"Total projects: {len(projects)}")
print(f"With images: {uploaded}")
print(f"Without images: {skipped}")
print(f"\nTo add images:")
print(f"1. Search online using the 'image_search' terms in real_ph_research_projects.json")
print(f"2. Download and save to scripts/images/ folder")
print(f"3. Run this script again to update")
