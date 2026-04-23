# 🚀 QUICK START - Android + MongoDB

## ⚡ 3 Steps to Run

### 1️⃣ Start Backend
```bash
cd services/api_fastapi
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2️⃣ Update IP (Physical Device Only)
Edit `apps/mobile_flutter/lib/services/api_service.dart` line 32:
```dart
return 'http://YOUR_PC_IP:8000/api/v1';  // Replace YOUR_PC_IP
```

**Find your IP:**
- Windows: `ipconfig`
- Mac/Linux: `ifconfig`

**For Emulator:** No change needed! Already uses `10.0.2.2`

### 3️⃣ Run Flutter App
```bash
cd apps/mobile_flutter
flutter run
```

---

## ✅ What Works

### Issues (Community Reports)
- ✅ Create, Read, Update, Delete
- ✅ View on map
- ✅ AI validation
- ✅ Status management

### Research Posts (Innovation Funding)
- ✅ Create, Read, Update, Delete
- ✅ Like and fund
- ✅ Comments
- ✅ SDG tagging

---

## 🔧 Troubleshooting

### Can't connect from Android?

**Emulator:**
```dart
// Should be (already set):
'http://10.0.2.2:8000/api/v1'
```

**Physical Device:**
1. PC and phone on same WiFi? ✓
2. Backend running with `--host 0.0.0.0`? ✓
3. Correct IP in code? ✓
4. Test in phone browser: `http://YOUR_IP:8000/docs`

### Port already in use?
```bash
# Use different port
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001

# Update Flutter code to :8001
```

---

## 📚 Documentation

- `ANDROID_MONGODB_COMPLETE.md` - Full guide
- `ANDROID_SETUP.md` - Detailed Android setup
- `CRUD_MONGODB.md` - API documentation
- `API_REFERENCE.md` - Endpoint reference

---

## 🧪 Test It

### Backend Test
```bash
cd services/api_fastapi
python test_crud.py
```

### API Docs
http://localhost:8000/docs

### From Phone Browser
http://YOUR_PC_IP:8000/docs

---

## 📱 Flutter CRUD Examples

```dart
final api = ApiService();

// CREATE
await api.submitIssue(
  reporterId: 'user_123',
  title: 'Road Damage',
  description: 'Potholes',
  lat: 14.5995,
  lng: 120.9842,
);

// READ
final issues = await api.getIssues();

// UPDATE
await api.updateIssue(
  issueId: id,
  title: 'Updated',
);

// DELETE
await api.deleteIssue(id);
```

---

## ✅ Status

**Backend:** ✅ MongoDB + FastAPI working
**Android:** ✅ Full CRUD ready
**Permissions:** ✅ Configured
**Network:** ✅ Set up

**YOU'RE READY TO GO!** 🎉

---

## 💡 Remember

1. Backend must use `--host 0.0.0.0`
2. Physical device needs correct IP
3. Emulator uses `10.0.2.2` (already set)
4. Phone and PC on same WiFi
5. Test in browser first

---

**Need help?** Check `ANDROID_MONGODB_COMPLETE.md`
