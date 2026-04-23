import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

uri = os.getenv("MONGODB_URI")
db_name = os.getenv("MONGODB_DB_NAME")

print(f"Connecting to: {uri}")
try:
    client = MongoClient(uri)
    # The ismaster command is cheap and does not require auth.
    client.admin.command('ismaster')
    print("MongoDB connection successful!")
    db = client[db_name]
    print(f"Database: {db.name}")
    print(f"Collections: {db.list_collection_names()}")
except Exception as e:
    print(f"MongoDB connection failed: {e}")
