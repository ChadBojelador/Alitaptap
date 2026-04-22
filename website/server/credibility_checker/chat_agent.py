import os
import json
import sys
import asyncio
import urllib.request
from dotenv import load_dotenv
from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai.types import Content, Part

load_dotenv(os.path.join(os.path.dirname(__file__), '.env'), override=False)

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

def is_research_question(message):
    """Ask the LLM first if it's research-related before spending a Serper query."""
    try:
        agent = Agent(
            name="classifier",
            model=model_provider,
            instruction="You are a classifier. Reply with only YES if the user message is related to research, fact-checking, source verification, credibility analysis, academic topics, or news verification. Reply with only NO otherwise."
        )
        session_service = InMemorySessionService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        session = loop.run_until_complete(session_service.create_session(app_name="AlitaptapApp", user_id="user"))
        runner = Runner(agent=agent, app_name="AlitaptapApp", session_service=session_service)
        msg = Content(parts=[Part(text=message)], role="user")
        events = runner.run(user_id="user", session_id=session.id, new_message=msg)
        reply = ""
        for event in events:
            if hasattr(event, 'content') and event.content and event.content.parts:
                for part in event.content.parts:
                    if hasattr(part, 'text') and part.text:
                        reply += part.text
        return "YES" in reply.strip().upper()
    except Exception:
        return False

def chat(message):
    try:
        # Step 1: classify first — no Serper used yet
        research = is_research_question(message)

        # Step 2: only search if it's a research question
        urls_context = ""
        if research:
            search_urls = serper_search(message, num=3)
            urls_context = "\n".join(search_urls) if search_urls else ""

        # Step 3: build instruction
        if not research:
            instruction = """You are Alitaptap's research assistant. Your ONLY purpose is to help with research-related questions.
If the user's question is NOT related to research, fact-checking, or information verification, respond ONLY with:
"I'm only able to assist with research-related questions such as fact-checking, source verification, and credibility analysis." """
        elif urls_context:
            instruction = f"""You are Alitaptap's research assistant. Answer the research question clearly and helpfully.
At the end, include a "Sources:" section using ONLY these real URLs — do not invent any:
{urls_context}
List each URL on its own line starting with http."""
        else:
            instruction = """You are Alitaptap's research assistant. Answer the research question clearly and helpfully.
Do not include any source URLs."""

        agent = Agent(name="chat_agent", model=model_provider, instruction=instruction)
        session_service = InMemorySessionService()
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        session = loop.run_until_complete(session_service.create_session(app_name="AlitaptapApp", user_id="user"))
        runner = Runner(agent=agent, app_name="AlitaptapApp", session_service=session_service)
        msg = Content(parts=[Part(text=message)], role="user")
        events = runner.run(user_id="user", session_id=session.id, new_message=msg)

        reply = ""
        for event in events:
            if hasattr(event, 'content') and event.content and event.content.parts:
                for part in event.content.parts:
                    if hasattr(part, 'text') and part.text:
                        reply += part.text

        return {"reply": reply.strip()}

    except Exception as e:
        return {"error": str(e)}

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
