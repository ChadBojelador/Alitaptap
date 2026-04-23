# 📱 Android Setup Guide - MongoDB CRUD API

## ✅ What's Ready

Your app is now ready to work on Android with full CRUD operations using MongoDB!

### Backend (FastAPI + MongoDB)
- ✅ Full CRUD operations implemented
- ✅ MongoDB Atlas connected
- ✅ All endpoints working

### Flutter Mobile App
- ✅ API service updated with UPDATE and DELETE methods
- ✅ Android network configuration ready
- ✅ CRUD methods available for both Issues and Posts

## 🚀 Setup Steps

### 1. Start the Backend API

```bash
cd services/api_fastapi
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Important:** Use `--host 0.0.0.0` to allow connections from your Android device!

### 2. Configure API URL for Android

#### Option A: Android Emulator
The API service is already configured to use `10.0.2.2` for emulators:
```dart
// In api_service.dart (already set)
return 'http://10.0.2.2:8000/api/v1';
```

#### Option B: Physical Android Device
1. Find your PC's local IP address:
   - Windows: `ipconfig` (look for IPv4 Address)
   - Mac/Linux: `ifconfig` or `ip addr`

2. Update the IP in `lib/services/api_service.dart`:
```dart
// Change this line (around line 32)
return 'http://192.168.0.139:8000/api/v1';  // Replace with YOUR PC's IP
```

3. Make sure your phone and PC are on the same WiFi network!

### 3. Update Android Network Permissions

The permissions are likely already set, but verify in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application
        android:usesCleartextTraffic="true"
        ...>
        ...
    </application>
</manifest>
```

### 4. Build and Run on Android

```bash
cd apps/mobile_flutter

# For emulator
flutter run

# For physical device (connect via USB)
flutter run -d <device-id>

# List connected devices
flutter devices
```

## 📋 Available CRUD Operations in Flutter

### Issues (Community Reports)

```dart
final apiService = ApiService();

// CREATE
await apiService.submitIssue(
  reporterId: 'user_123',
  title: 'Road Damage',
  description: 'Potholes on main street',
  lat: 14.5995,
  lng: 120.9842,
);

// READ
final issues = await apiService.getIssues();
final issue = await apiService.getIssue(issueId);

// UPDATE
await apiService.updateIssue(
  issueId: issueId,
  title: 'Updated Title',
  description: 'Updated description',
);

// DELETE
await apiService.deleteIssue(issueId);
```

### Research Posts (Innovation Funding)

```dart
// CREATE
await apiService.createPost(
  authorId: 'researcher_123',
  authorEmail: 'researcher@example.com',
  title: 'Research Title',
  abstract: 'Research abstract',
  problemSolved: 'Problem description',
  sdgTags: ['SDG 11'],
  fundingGoal: 50000.0,
);

// READ
final posts = await apiService.getPosts();
final post = await apiService.getPost(postId);

// UPDATE
await apiService.updatePost(
  postId: postId,
  title: 'Updated Title',
  fundingGoal: 75000.0,
);

// DELETE
await apiService.deletePost(postId);
```

## 🔧 Troubleshooting

### "Failed to connect" error

1. **Check backend is running:**
   ```bash
   curl http://localhost:8000/api/v1/health
   ```

2. **For emulator:** Make sure you're using `10.0.2.2`

3. **For physical device:**
   - Verify PC and phone are on same WiFi
   - Check firewall isn't blocking port 8000
   - Verify IP address is correct

4. **Test from phone browser:**
   - Open browser on phone
   - Navigate to `http://YOUR_PC_IP:8000/docs`
   - If this doesn't work, it's a network issue

### "Cleartext HTTP traffic not permitted"

Add to `AndroidManifest.xml`:
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

### Port 8000 already in use

```bash
# Use different port
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001

# Update Flutter code to use :8001
```

## 🧪 Testing on Android

### 1. Test Backend Connection
```dart
// In your Flutter app, add a test button:
ElevatedButton(
  onPressed: () async {
    try {
      final issues = await apiService.getIssues();
      print('✅ Connected! Found ${issues.length} issues');
    } catch (e) {
      print('❌ Connection failed: $e');
    }
  },
  child: Text('Test API Connection'),
)
```

### 2. Test CRUD Operations
The app already has UI for:
- ✅ Creating issues (Issue Submit Page)
- ✅ Viewing issues (Issue Map Page, Expo Page)
- ✅ Creating posts (Create Post Page)
- ✅ Viewing posts (Expo Feed Page)

You can now add UPDATE and DELETE buttons to the UI!

## 📱 Example: Add Delete Button to Issue Detail

```dart
// In issue_detail_page.dart
ElevatedButton.icon(
  icon: Icon(Icons.delete),
  label: Text('Delete Issue'),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Issue?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await apiService.deleteIssue(issueId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Issue deleted')),
      );
    }
  },
)
```

## 🎯 Quick Start Checklist

- [ ] Backend running with `--host 0.0.0.0`
- [ ] Correct IP address in `api_service.dart`
- [ ] Android permissions set in `AndroidManifest.xml`
- [ ] Phone and PC on same WiFi (for physical device)
- [ ] Test connection from phone browser
- [ ] Run Flutter app on Android
- [ ] Test CRUD operations

## 📊 Network Configuration Summary

| Environment | API Base URL | Notes |
|-------------|--------------|-------|
| Android Emulator | `http://10.0.2.2:8000/api/v1` | Already configured |
| Physical Device | `http://YOUR_PC_IP:8000/api/v1` | Update with your IP |
| Web | `http://127.0.0.1:8000/api/v1` | Already configured |

## ✅ You're Ready!

Your Android app can now:
- ✅ Create issues and posts
- ✅ Read/view issues and posts
- ✅ Update issues and posts
- ✅ Delete issues and posts
- ✅ All data stored in MongoDB Atlas
- ✅ Works on both emulator and physical devices

Just start the backend and run the Flutter app! 🚀
