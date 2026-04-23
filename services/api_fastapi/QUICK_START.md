# 🚀 Quick Start Guide - MongoDB CRUD API

## Prerequisites
- Python 3.10+
- MongoDB Atlas account (already configured)
- pip package manager

## Installation

### 1. Navigate to API directory
```bash
cd services/api_fastapi
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

## Running the API

### Start the server
```bash
uvicorn app.main:app --reload --port 8000
```

The API will be available at:
- **API Base URL:** http://localhost:8000
- **Interactive Docs:** http://localhost:8000/docs
- **Alternative Docs:** http://localhost:8000/redoc

## Testing CRUD Operations

### Option 1: Use the test script
```bash
python test_crud.py
```

### Option 2: Use the interactive docs
1. Open http://localhost:8000/docs
2. Try the endpoints directly in the browser

### Option 3: Use curl

**Create an issue:**
```bash
curl -X POST http://localhost:8000/api/v1/issues \
  -H "Content-Type: application/json" \
  -d '{
    "reporter_id": "test_user",
    "reporter_name": "Test User",
    "title": "Test Issue",
    "description": "This is a test issue",
    "lat": 14.5995,
    "lng": 120.9842
  }'
```

**Get all issues:**
```bash
curl http://localhost:8000/api/v1/issues
```

**Update an issue:**
```bash
curl -X PUT http://localhost:8000/api/v1/issues/{issue_id} \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Title"
  }'
```

**Delete an issue:**
```bash
curl -X DELETE http://localhost:8000/api/v1/issues/{issue_id}
```

## Available Endpoints

### Issues (Community Reports)
- `POST /api/v1/issues` - Create issue
- `GET /api/v1/issues` - List issues
- `GET /api/v1/issues/{id}` - Get issue
- `PUT /api/v1/issues/{id}` - Update issue
- `DELETE /api/v1/issues/{id}` - Delete issue
- `PATCH /api/v1/issues/{id}/status` - Update status

### Research Posts (Innovation Funding)
- `POST /api/v1/posts` - Create post
- `GET /api/v1/posts` - List posts
- `GET /api/v1/posts/{id}` - Get post
- `PUT /api/v1/posts/{id}` - Update post
- `DELETE /api/v1/posts/{id}` - Delete post

## MongoDB Configuration

The MongoDB connection is already configured in `.env`:
```env
MONGODB_URI=mongodb+srv://2405501_db_user:WHDcTdtgghSua63g@cluster0.9r9aujq.mongodb.net/?appName=Cluster0
MONGODB_DB_NAME=alitaptap
```

## Troubleshooting

### MongoDB connection error
- Check your internet connection
- Verify MongoDB Atlas cluster is running
- Check credentials in `.env` file

### Port already in use
```bash
# Use a different port
uvicorn app.main:app --reload --port 8001
```

### Module not found
```bash
# Reinstall dependencies
pip install -r requirements.txt
```

## Documentation Files

- `CRUD_MONGODB.md` - Complete CRUD documentation
- `API_REFERENCE.md` - Quick reference guide
- `IMPLEMENTATION_SUMMARY.md` - Implementation details
- `QUICK_START.md` - This file

## Next Steps

1. ✅ Start the API server
2. ✅ Test CRUD operations
3. ✅ View interactive docs
4. 🔄 Integrate with Flutter mobile app
5. 🔄 Deploy to production

## Support

For issues or questions:
1. Check the documentation files
2. View API docs at http://localhost:8000/docs
3. Review the test script: `test_crud.py`

---

**Status:** ✅ All CRUD operations working with MongoDB
**Last Updated:** 2024
