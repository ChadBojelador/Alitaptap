"""Quick test to verify backend is running and working"""
import sys
import requests

def test_backend():
    base_url = "http://localhost:8000"
    
    print("=" * 50)
    print("Testing Alitaptap Backend")
    print("=" * 50)
    
    # Test 1: Health check
    print("\n1. Testing health endpoint...")
    try:
        response = requests.get(f"{base_url}/api/v1/health", timeout=5)
        if response.status_code == 200:
            print("   ✅ Health check passed")
        else:
            print(f"   ❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Cannot connect to backend: {e}")
        print("\n   Make sure the backend is running:")
        print("   Run: START_BACKEND.bat")
        return False
    
    # Test 2: Get issues
    print("\n2. Testing GET /api/v1/issues...")
    try:
        response = requests.get(f"{base_url}/api/v1/issues", timeout=5)
        if response.status_code == 200:
            issues = response.json()
            print(f"   ✅ GET issues passed - Found {len(issues)} issues")
        else:
            print(f"   ❌ GET issues failed: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Test 3: Get posts
    print("\n3. Testing GET /api/v1/posts...")
    try:
        response = requests.get(f"{base_url}/api/v1/posts", timeout=5)
        if response.status_code == 200:
            posts = response.json()
            print(f"   ✅ GET posts passed - Found {len(posts)} posts")
        else:
            print(f"   ❌ GET posts failed: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Test 4: Create issue (test CRUD)
    print("\n4. Testing POST /api/v1/issues (CREATE)...")
    try:
        test_issue = {
            "reporter_id": "test_user",
            "reporter_name": "Test User",
            "title": "Test Issue - Please Delete",
            "description": "This is a test issue to verify CRUD operations work",
            "lat": 14.5995,
            "lng": 120.9842
        }
        response = requests.post(
            f"{base_url}/api/v1/issues",
            json=test_issue,
            timeout=10
        )
        if response.status_code == 200:
            created = response.json()
            issue_id = created.get("issue_id")
            print(f"   ✅ CREATE issue passed - ID: {issue_id}")
            
            # Test 5: Update issue
            print("\n5. Testing PUT /api/v1/issues/{id} (UPDATE)...")
            update_data = {"title": "Updated Test Issue"}
            response = requests.put(
                f"{base_url}/api/v1/issues/{issue_id}",
                json=update_data,
                timeout=5
            )
            if response.status_code == 200:
                print("   ✅ UPDATE issue passed")
            else:
                print(f"   ❌ UPDATE failed: {response.status_code}")
            
            # Test 6: Delete issue
            print("\n6. Testing DELETE /api/v1/issues/{id} (DELETE)...")
            response = requests.delete(
                f"{base_url}/api/v1/issues/{issue_id}",
                timeout=5
            )
            if response.status_code == 200:
                print("   ✅ DELETE issue passed")
            else:
                print(f"   ❌ DELETE failed: {response.status_code}")
        else:
            print(f"   ❌ CREATE issue failed: {response.status_code}")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print("✅ Backend is working correctly!")
    print("=" * 50)
    print("\nYou can now:")
    print("1. View API docs: http://localhost:8000/docs")
    print("2. Run Flutter app: cd apps/mobile_flutter && flutter run")
    print("3. Test on Android emulator or device")
    return True

if __name__ == "__main__":
    success = test_backend()
    sys.exit(0 if success else 1)
