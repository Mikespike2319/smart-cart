from typing import Dict
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from api.database import get_db
from api.services.analytics import AnalyticsService
from api.auth import get_current_user
from api.models import User

router = APIRouter(
    prefix="/analytics",
    tags=["analytics"]
)

@router.get("/savings")
async def get_savings(
    days: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict:
    """Get user's savings analytics."""
    analytics_service = AnalyticsService(db)
    return analytics_service.get_user_savings(current_user.id, days)

@router.get("/products/{product_id}/trends")
async def get_product_trends(
    product_id: int,
    days: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict:
    """Get price trends for a specific product."""
    analytics_service = AnalyticsService(db)
    return analytics_service.get_price_trends(product_id, days)

@router.get("/insights")
async def get_user_insights(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict:
    """Get insights about user's shopping behavior."""
    analytics_service = AnalyticsService(db)
    return analytics_service.get_user_insights(current_user.id)

@router.get("/products/{product_id}/store-comparison")
async def get_store_comparison(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict:
    """Compare prices across different stores for a product."""
    analytics_service = AnalyticsService(db)
    return analytics_service.get_store_comparison(product_id) 