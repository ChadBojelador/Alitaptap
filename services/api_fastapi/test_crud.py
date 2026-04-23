"""Test CRUD operations for Issues API with MongoDB"""
import requests
import json

BASE_URL = "http://localhost:8000/api/v1/issues"

def test_crud():
    # CREATE
    print("1. Creating issue...")
    create_data = {
        "reporter_id": "test_user_001",
        "reporter_name": "Test User",
        "title": "Test Issue",
        "description": "This is a test issue for CRUD operations",
        "lat": 14.5995,
        "lng": 120.9842,
        "image_urls": ["http://example.com/image.jpg"],
        "caption": "Test caption"
    }
    response = requests.post(BASE_URL, json=create_data)
    print(f"Status: {response.status_code}")
    created = response.json()
    print(f"Created: {json.dumps(created, indent=2)}")
    issue_id = created["issue_id"]
    
    # READ (single)
    print(f"\n2. Reading issue {issue_id}...")
    response = requests.get(f"{BASE_URL}/{issue_id}")
    print(f"Status: {response.status_code}")
    print(f"Issue: {json.dumps(response.json(), indent=2)}")
    
    # READ (list)
    print("\n3. Listing all issues...")
    response = requests.get(BASE_URL)
    print(f"Status: {response.status_code}")
    print(f"Count: {len(response.json())}")
    
    # UPDATE
    print(f"\n4. Updating issue {issue_id}...")
    update_data = {
        "title": "Updated Test Issue",
        "description": "Updated description"
    }
    response = requests.put(f"{BASE_URL}/{issue_id}", json=update_data)
    print(f"Status: {response.status_code}")
    print(f"Updated: {json.dumps(response.json(), indent=2)}")
    
    # DELETE
    print(f"\n5. Deleting issue {issue_id}...")
    response = requests.delete(f"{BASE_URL}/{issue_id}")
    print(f"Status: {response.status_code}")
    print(f"Result: {json.dumps(response.json(), indent=2)}")
    
    # Verify deletion
    print(f"\n6. Verifying deletion...")
    response = requests.get(f"{BASE_URL}/{issue_id}")
    print(f"Status: {response.status_code} (should be 404)")

if __name__ == "__main__":
    test_crud()
