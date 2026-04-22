import os
import json
import sys
import re
import asyncio
import urllib.request
import urllib.parse
from dotenv import load_dotenv
from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai.types import Content, Part

load_dotenv(os.path.join(os.path.dirname(__file__), '.env'), override=False)

PERSONAS = {
    "1": {"name": "High School Student", "voice": "Casual, relatable, easy to understand."},
    "2": {"name": "College Student",     "voice": "Analytical, structured, academic."},
    "3": {"name": "Professional",        "voice": "Meticulous, expert, formal tone."}
}

model_provider = LiteLlm(
    model="groq/llama-3.3-70b-versatile",
    api_key=os.getenv("GROQ_API_KEY")
)

def serper_search(query, num=3):
    try:
        api_key = os.getenv("SERPER_API_KEY")
        if not api_key or api_key == "your_serper_api_key_here":
            return []
        data = json.dumps({"q": query, "num": num}).encode("utf-8")
        req = urllib.request.Request(
            "https://google.serper.dev/search",
            data=data,
            headers={"X-API-KEY": api_key, "Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=8) as res:
            results = json.loads(res.read())
        return [r["link"] for r in results.get("organic", [])[:num]]
    except Exception:
        return []

def check_credibility(user_query, persona_index="1"):
    try:
        persona_data = PERSONAS.get(persona_index, PERSONAS["1"])

        # 1 Serper query for source URLs only
        search_urls = serper_search(user_query, num=3)
        urls_context = "\n".join(search_urls) if search_urls else "No search results available."

        prompt = f"""
ROLE: You are a {persona_data['name']}.
TONE: {persona_data['voice']}

REAL SOURCE URLS FROM SEARCH (use ONLY these, do not invent any URLs):
{urls_context}

MISSION:
1. Analyze the input and break it into 3 specific claims.
2. For each claim, assign one of the URLs above as source_url. Do NOT make up URLs.
3. Provide 3 concise suggestions to improve the writing's credibility, each using one of the URLs above.
4. Write a suggested summary of the text rewritten with proper APA in-text citations.
5. Return ONLY a valid JSON object.

REQUIRED JSON FORMAT:
{{
  "overall_credibility_score": 0,
  "summary": "...",
  "apa_summary": "A rewritten version of the text with proper APA in-text citations (Author, Year) and a References section at the end.",
  "findings": [
    {{
      "claim": "...",
      "accuracy_percentage": 0,
      "analysis": "...",
      "source_url": "one of the URLs listed above"
    }}
  ],
  "suggestions": [
    {{ "text": "Suggestion 1...", "url": "one of the URLs listed above" }},
    {{ "text": "Suggestion 2...", "url": "one of the URLs listed above" }},
    {{ "text": "Suggestion 3...", "url": "one of the URLs listed above" }}
  ]
}}
"""
        agent = Agent(name="credibility_checker", model=model_provider, instruction=prompt)
        session_service = InMemorySessionService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        session = loop.run_until_complete(session_service.create_session(app_name="AlitaptapApp", user_id="user"))

        agent_runner = Runner(agent=agent, app_name="AlitaptapApp", session_service=session_service)
        message = Content(parts=[Part(text=user_query)], role="user")
        events = agent_runner.run(user_id="user", session_id=session.id, new_message=message)

        text_output = ""
        for event in events:
            if hasattr(event, 'content') and event.content and event.content.parts:
                for part in event.content.parts:
                    if hasattr(part, 'text') and part.text:
                        text_output += part.text

        json_match = re.search(r'\{.*\}', text_output, re.DOTALL)
        data = json.loads(json_match.group() if json_match else text_output)

        findings = data.get("findings", [])
        if findings:
            data["overall_credibility_score"] = round(
                sum(f.get("accuracy_percentage", 0) for f in findings) / len(findings)
            )

        return data

    except Exception as e:
        return {"error": f"AI Generation Error: {str(e)}"}

if __name__ == "__main__":
    raw = sys.stdin.read().strip()
    if raw:
        try:
            payload = json.loads(raw)
            user_input = payload.get("text", "")
            persona_index = payload.get("persona", "1")
        except Exception:
            user_input = raw
            persona_index = "1"
    else:
        persona_index = sys.argv[-1] if len(sys.argv) > 2 and sys.argv[-1] in PERSONAS else "1"
        user_input = " ".join(sys.argv[1:-1]) if len(sys.argv) > 2 else (" ".join(sys.argv[1:]) if len(sys.argv) > 1 else "The earth is flat.")
    try:
        result = check_credibility(user_input, persona_index)
    except Exception as e:
        result = {"error": str(e)}
    sys.stdout.write(json.dumps(result))
    sys.stdout.flush()
    os._exit(0)
