import os
import requests
from typing import Optional
from pydantic import BaseModel
from app.services.ai_validator import AIValidator

class NewsArticle(BaseModel):
    title: str
    source: str
    url: str
    summary: str
    published_at: str

class NewsService:
    def __init__(self):
        self.api_key = os.getenv("NEWSAPI_KEY", "6e88128b534d4da09f7f41a12eaece92")
        self.base_url = "https://newsapi.org/v2"
        self.ai_validator = AIValidator()

    async def fetch_news(
        self,
        keywords: Optional[str] = None,
        sdg_tags: Optional[list[str]] = None,
        country: str = "ph",
        page_size: int = 3,
    ) -> list[NewsArticle]:
        """
        Fetch news articles related to SDGs, research, and Philippine news.
        Summarize each article to 1 sentence using AI.
        """
        try:
            # Build search query
            query_parts = []
            
            if keywords:
                query_parts.append(keywords)
            
            if sdg_tags:
                sdg_query = " OR ".join(sdg_tags)
                query_parts.append(f"({sdg_query})")
            else:
                # Default SDG-related keywords
                default_sdgs = [
                    "sustainable development",
                    "climate change",
                    "poverty",
                    "education",
                    "health",
                    "clean water",
                    "renewable energy",
                    "research",
                ]
                query_parts.append(f"({' OR '.join(default_sdgs)})")
            
            query = " ".join(query_parts)
            
            # Fetch from NewsAPI
            params = {
                "q": query,
                "country": country,
                "apiKey": self.api_key,
                "pageSize": page_size,
                "sortBy": "publishedAt",
            }
            
            response = requests.get(f"{self.base_url}/everything", params=params)
            response.raise_for_status()
            
            data = response.json()
            articles = data.get("articles", [])
            
            # Process articles and summarize
            news_items = []
            for article in articles:
                summary = await self._summarize_article(article)
                news_item = NewsArticle(
                    title=article.get("title", ""),
                    source=article.get("source", {}).get("name", "Unknown"),
                    url=article.get("url", ""),
                    summary=summary,
                    published_at=article.get("publishedAt", ""),
                )
                news_items.append(news_item)
            
            return news_items
        
        except Exception as e:
            print(f"Error fetching news: {e}")
            return []

    async def _summarize_article(self, article: dict) -> str:
        """
        Summarize an article to 1 sentence using AI.
        """
        try:
            title = article.get("title", "")
            description = article.get("description", "")
            content = article.get("content", "")
            
            # Combine available text
            full_text = f"{title}. {description}. {content}".strip()
            
            # Use AI to summarize to 1 sentence
            prompt = f"""Summarize the following news article in exactly 1 sentence. 
The summary should be concise, informative, and highlight the key point.
Do not include source attribution or quotes.

Article:
{full_text}

Summary:"""
            
            summary = await self.ai_validator._call_openai(prompt)
            return summary.strip() if summary else description or title
        
        except Exception as e:
            print(f"Error summarizing article: {e}")
            # Fallback to description or title
            return article.get("description") or article.get("title", "")

    async def fetch_sdg_news(
        self,
        sdg_number: Optional[int] = None,
        page_size: int = 3,
    ) -> list[NewsArticle]:
        """
        Fetch news specifically related to a UN SDG.
        """
        sdg_keywords = {
            1: "poverty elimination",
            2: "zero hunger food security",
            3: "good health wellbeing",
            4: "quality education",
            5: "gender equality",
            6: "clean water sanitation",
            7: "affordable clean energy",
            8: "decent work economic growth",
            9: "industry innovation infrastructure",
            10: "reduced inequalities",
            11: "sustainable cities communities",
            12: "responsible consumption production",
            13: "climate action",
            14: "life below water marine",
            15: "life on land biodiversity",
            16: "peace justice institutions",
            17: "partnerships sustainable development",
        }
        
        sdg_tag = sdg_keywords.get(sdg_number) if sdg_number else None
        sdg_tags = [sdg_tag] if sdg_tag else list(sdg_keywords.values())
        
        return await self.fetch_news(sdg_tags=sdg_tags, page_size=page_size)

    async def fetch_research_news(self, page_size: int = 3) -> list[NewsArticle]:
        """
        Fetch news related to research and academic topics.
        """
        return await self.fetch_news(
            keywords="research OR study OR university OR academic",
            page_size=page_size,
        )

    async def fetch_philippines_news(self, page_size: int = 3) -> list[NewsArticle]:
        """
        Fetch news from Philippines.
        """
        return await self.fetch_news(country="ph", page_size=page_size)
