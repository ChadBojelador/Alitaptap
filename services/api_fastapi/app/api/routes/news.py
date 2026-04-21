from fastapi import APIRouter, Query
from typing import Optional
from app.services.news_service import NewsService, NewsArticle

router = APIRouter(prefix="/api/v1/news", tags=["news"])
news_service = NewsService()

@router.get("", response_model=list[NewsArticle])
async def get_news(
    keywords: Optional[str] = Query(None, description="Search keywords"),
    sdg: Optional[int] = Query(None, description="UN SDG number (1-17)"),
    country: str = Query("ph", description="Country code (default: ph for Philippines)"),
    page_size: int = Query(10, ge=1, le=50, description="Number of articles to fetch"),
) -> list[NewsArticle]:
    """
    Fetch news articles related to SDGs, research, and community topics.
    Each article includes a 1-sentence AI-generated summary.
    
    Query Parameters:
    - keywords: Search keywords (e.g., "climate change", "education")
    - sdg: UN SDG number (1-17) to filter by specific goal
    - country: Country code (default: ph for Philippines)
    - page_size: Number of articles (1-50, default: 10)
    """
    if sdg:
        return await news_service.fetch_sdg_news(sdg_number=sdg, page_size=page_size)
    
    return await news_service.fetch_news(
        keywords=keywords,
        country=country,
        page_size=page_size,
    )

@router.get("/sdg/{sdg_number}", response_model=list[NewsArticle])
async def get_sdg_news(
    sdg_number: int = Query(..., ge=1, le=17, description="UN SDG number"),
    page_size: int = Query(10, ge=1, le=50),
) -> list[NewsArticle]:
    """
    Fetch news specifically related to a UN Sustainable Development Goal.
    """
    return await news_service.fetch_sdg_news(sdg_number=sdg_number, page_size=page_size)

@router.get("/research", response_model=list[NewsArticle])
async def get_research_news(
    page_size: int = Query(10, ge=1, le=50),
) -> list[NewsArticle]:
    """
    Fetch news related to research and academic topics.
    """
    return await news_service.fetch_research_news(page_size=page_size)

@router.get("/philippines", response_model=list[NewsArticle])
async def get_philippines_news(
    page_size: int = Query(10, ge=1, le=50),
) -> list[NewsArticle]:
    """
    Fetch news from Philippines.
    """
    return await news_service.fetch_philippines_news(page_size=page_size)
