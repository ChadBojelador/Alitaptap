#!/usr/bin/env python3
"""Check image URLs in research posts."""

import firebase_admin
from firebase_admin import credentials, firestore
import json

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("../secrets/firebase-service-account.json")
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("Checking image URLs in research posts...\n")

posts = db.collection("research_posts").stream()

for post in posts:
    data = post.to_dict()
    print(f"Post: {data.get('title')}")
    print(f"  image_url: {data.get('image_url')}")
    print(f"  image_urls: {data.get('image_urls')}")
    print()
