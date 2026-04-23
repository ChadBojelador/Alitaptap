# 🔧 ERROR DIAGNOSIS & FIXES

## Current Error

```
ApiService.getPosts failed: Exception: Network request failed (Failed to fetch)
```

**Cause:** The Flutter app cannot connect to the backend API because it's not running.

---

## ✅ SOLUTION - Start the Backend

### Option 1: Use the Batch Script (Easiest)
```bash
# Double-click this file:
START_BACKEND.bat

# Or run from command line:
cd "c:\Users\Chad Bojelador\Desktop\New folder (24)\Alitaptap"
START_BACKEND.bat
```

### Option 2: Manual Start
```bash
cd "c:\Users\Chad Bojelador\Desktop\New folder (24)\Alitaptap\services\api_fastapi"
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Option 3: Use existing batch file
```bash
cd "c:\Users\Chad Bojelador\Desktop\New folder (24)\Alitaptap"
run_backend.bat
```

---

## 🧪 Test the Backend

After starting the backend, run:

```bash
cd "c:\Users\Chad Bojelador\Desktop\New folder (24)\Alitaptap"
python TEST_BACKEND.py
```

This will test:
- ✅ Health check
- ✅ GET issues
- ✅ GET posts
- ✅ CREATE issue
- ✅ UPDATE issue
- ✅ DELETE issue

---

## 🔍 Common Errors & Fixes

### Error 1: "uvicorn is not recognized"

**Fix:** Install dependencies
```bash
cd services\api_fastapi
pip install -r requirements.txt
```

### Error 2: "ModuleNotFoundError: No module named 'app'"

**Fix:** Make sure you're in the correct directory
```bash
cd services\api_fastapi
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Error 3: "Port 8000 is already in use"

**Fix:** Use a different port
```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

Then update Flutter code in `apps/mobile_flutter/lib/services/api_service.dart`:
```dart
return 'http://127.0.0.1:8001/api/v1';  // Change 8000 to 8001
```

### Error 4: "MongoDB connection failed"

**Fix:** Check your .env file has the correct MongoDB URI
```bash
# File: services/api_fastapi/.env
MONGODB_URI=mongodb+srv://2405501_db_user:WHDcTdtgghSua63g@cluster0.9r9aujq.mongodb.net/?appName=Cluster0
MONGODB_DB_NAME=alitaptap
```

### Error 5: Flutter compilation error

**Fix:** Clean and rebuild
```bash
cd apps\mobile_flutter
flutter clean
flutter pub get
flutter run
```

---

## 📱 Running on Android

### Step 1: Start Backend
```bash
START_BACKEND.bat
```

### Step 2: Verify Backend is Running
Open browser: http://localhost:8000/docs

### Step 3: Run Flutter App

**For Emulator:**
```bash
cd apps\mobile_flutter
flutter run
```

**For Physical Device:**
1. Update IP in `lib/services/api_service.dart` line 32
2. Find your IP: `ipconfig` (Windows)
3. Change to: `return 'http://YOUR_IP:8000/api/v1';`
4. Run: `flutter run`

---

## ✅ Verification Checklist

- [ ] Backend is running (http://localhost:8000/docs works)
- [ ] TEST_BACKEND.py passes all tests
- [ ] MongoDB connection successful
- [ ] Flutter app compiles without errors
- [ ] API calls work from Flutter app

---

## 🚀 Quick Start Commands

```bash
# Terminal 1: Start Backend
cd "c:\Users\Chad Bojelador\Desktop\New folder (24)\Alitaptap"
START_BACKEND.bat

# Terminal 2: Test Backend
python TEST_BACKEND.py

# Terminal 3: Run Flutter
cd apps\mobile_flutter
flutter run
```

---

## 📊 Expected Output

### Backend Running:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Test Script Success:
```
==================================================
Testing Alitaptap Backend
==================================================

1. Testing health endpoint...
   ✅ Health check passed

2. Testing GET /api/v1/issues...
   ✅ GET issues passed - Found X issues

3. Testing GET /api/v1/posts...
   ✅ GET posts passed - Found X posts

4. Testing POST /api/v1/issues (CREATE)...
   ✅ CREATE issue passed - ID: 67xxxxx

5. Testing PUT /api/v1/issues/{id} (UPDATE)...
   ✅ UPDATE issue passed

6. Testing DELETE /api/v1/issues/{id} (DELETE)...
   ✅ DELETE issue passed

==================================================
✅ Backend is working correctly!
==================================================
```

### Flutter App Success:
```
Flutter run key commands.
r Hot reload.
R Hot restart.
...
Application running on Chrome/Android
```

---

## 💡 Pro Tips

1. **Always start backend first** before running Flutter app
2. **Use --host 0.0.0.0** to allow Android connections
3. **Test in browser** (http://localhost:8000/docs) before testing in app
4. **Check firewall** if physical device can't connect
5. **Use same WiFi** for PC and phone

---

## 🆘 Still Having Issues?

1. Check all files are saved
2. Restart your terminal/command prompt
3. Make sure Python and Flutter are in PATH
4. Verify MongoDB Atlas is accessible
5. Check the documentation files:
   - QUICK_START_ANDROID.md
   - ANDROID_MONGODB_COMPLETE.md
   - CRUD_MONGODB.md

---

**Next Step:** Run `START_BACKEND.bat` then `TEST_BACKEND.py` to verify everything works!
