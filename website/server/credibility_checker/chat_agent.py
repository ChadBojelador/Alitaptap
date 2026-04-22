import os
import json
import sys
import urllib.request
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'), override=False)

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")

SYSTEM_PROMPT = """You are an AI project planner for ALITAPTAP — a platform that connects community problems to student research aligned with the UN SDGs.

When given a community problem or research idea, return EXACTLY this JSON (no markdown, no extra text, just raw JSON):
{
  "title": "Project title",
  "problem": "Problem it solves in 1-2 sentences",
  "features": ["feature 1", "feature 2", "feature 3", "feature 4", "feature 5"],
  "plan": [
    {"step": 1, "title": "Step title", "desc": "Detailed description of what to do"},
    {"step": 2, "title": "Step title", "desc": "Detailed description of what to do"},
    {"step": 3, "title": "Step title", "desc": "Detailed description of what to do"},
    {"step": 4, "title": "Step title", "desc": "Detailed description of what to do"},
    {"step": 5, "title": "Step title", "desc": "Detailed description of what to do"}
  ],
  "tech_stack": {
    "frontend": "technology name",
    "backend": "technology name",
    "database": "technology name",
    "ai": "technology name"
  },
  "folder_structure": "/project-name\\n  /frontend\\n    /src\\n    /public\\n  /backend\\n    /app\\n    /tests\\n  /docs\\n  README.md",
  "starter_code": "# full working starter code here",
  "sdg": "SDG X - Full SDG Name"
}"""


def call_groq(message):
    data = json.dumps({
        "model": "llama-3.3-70b-versatile",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": message}
        ],
        "temperature": 0.7,
        "max_tokens": 2500
    }).encode("utf-8")

    req = urllib.request.Request(
        "https://api.groq.com/openai/v1/chat/completions",
        data=data,
        headers={
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
    )
    with urllib.request.urlopen(req, timeout=30) as res:
        result = json.loads(res.read())
    return result["choices"][0]["message"]["content"].strip()


def call_openrouter(message):
    data = json.dumps({
        "model": "meta-llama/llama-3.3-70b-instruct",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": message}
        ],
        "temperature": 0.7,
        "max_tokens": 2500
    }).encode("utf-8")

    req = urllib.request.Request(
        "https://openrouter.ai/api/v1/chat/completions",
        data=data,
        headers={
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:5173",
            "X-Title": "ALITAPTAP"
        }
    )
    with urllib.request.urlopen(req, timeout=30) as res:
        result = json.loads(res.read())
    return result["choices"][0]["message"]["content"].strip()


def generate_fallback_plan(message):
    title = message[:80].strip()
    plan = {
        "title": f"Solution: {title}",
        "problem": message,
        "features": [
            "Community data collection and reporting",
            "Real-time monitoring dashboard",
            "AI-powered analysis and insights",
            "Alert and notification system",
            "Admin validation and management panel"
        ],
        "plan": [
            {"step": 1, "title": "Research & Requirements", "desc": "Define problem scope, interview community members, and document functional requirements."},
            {"step": 2, "title": "System Architecture", "desc": "Design database schema, REST API endpoints, and UI wireframes using Figma."},
            {"step": 3, "title": "Backend Development", "desc": "Build FastAPI backend with Firebase Firestore integration and authentication."},
            {"step": 4, "title": "Frontend Development", "desc": "Build React dashboard with real-time data visualization and map integration."},
            {"step": 5, "title": "Testing & Deployment", "desc": "Run unit and integration tests, gather community feedback, and deploy to production."}
        ],
        "tech_stack": {
            "frontend": "React + Vite + MapLibre GL",
            "backend": "FastAPI (Python)",
            "database": "Firebase Firestore",
            "ai": "Groq Llama 3.3 70B"
        },
        "folder_structure": "/project\n  /frontend\n    /src\n      /components\n      /pages\n    /public\n  /backend\n    /app\n      /api\n      /core\n    /tests\n  /docs\n  README.md",
        "starter_code": f"""# {title}
# ALITAPTAP AI-Generated Starter

from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime

app = FastAPI(title="{title}", version="1.0.0")

class Report(BaseModel):
    reporter_id: str
    title: str
    description: str
    lat: float
    lng: float

@app.get("/")
def root():
    return {{"project": "{title}", "status": "running", "timestamp": str(datetime.now())}}

@app.post("/reports")
def create_report(report: Report):
    return {{"id": "report_001", "status": "pending", "data": report.dict()}}

@app.get("/reports")
def list_reports():
    return {{"reports": [], "total": 0}}""",
        "sdg": "SDG 11 - Sustainable Cities and Communities"
    }
    return json.dumps(plan)


def chat(message):
    # Try Groq first
    if GROQ_API_KEY and GROQ_API_KEY != "your_groq_api_key_here":
        try:
            reply = call_groq(message)
            return {"reply": reply}
        except Exception:
            pass

    # Fallback to OpenRouter
    if OPENROUTER_API_KEY:
        try:
            reply = call_openrouter(message)
            return {"reply": reply}
        except Exception:
            pass

    # Final fallback: structured mock plan
    return {"reply": generate_fallback_plan(message)}


if __name__ == "__main__":
    raw = sys.stdin.read().strip()
    try:
        payload = json.loads(raw)
        message = payload.get("message", "")
    except Exception:
        message = raw

    result = chat(message)
    sys.stdout.write(json.dumps(result))
    sys.stdout.flush()
    os._exit(0)
