from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta

from ..database import get_db
from ..services.price_comparison import PriceComparisonService
from ..models import Product, Price, Store
from ..schemas.price_comparison import (
    PriceResponse,
    PriceHistoryResponse,
    PricePredictionResponse,
    DealResponse,
    PriceComparisonResponse,
    PriceAlertResponse
)

router = APIRouter(prefix="/products", tags=["price-comparison"])

@router.get("/{product_id}/prices", response_model=List[PriceResponse])
async def get_product_prices(
    product_id: int,
    db: Session = Depends(get_db)
):
    """Get current prices for a product across all stores."""
    service = PriceComparisonService(db)
    return service.get_product_prices(product_id)

@router.get("/{product_id}/price-history", response_model=List[PriceHistoryResponse])
async def get_price_history(
    product_id: int,
    days: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db)
):
    """Get price history for a product."""
    service = PriceComparisonService(db)
    return service.get_price_history(product_id, days)

@router.get("/{product_id}/price-predictions", response_model=List[PricePredictionResponse])
async def get_price_predictions(
    product_id: int,
    days_ahead: int = Query(7, ge=1, le=30),
    db: Session = Depends(get_db)
):
    """Get price predictions for a product."""
    service = PriceComparisonService(db)
    return service.predict_future_prices(product_id, days_ahead)

@router.get("/deals/best", response_model=List[DealResponse])
async def get_best_deals(
    category: Optional[str] = None,
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Get the best deals across all products."""
    service = PriceComparisonService(db)
    return service.find_best_deals(category, limit)

@router.post("/compare", response_model=List[PriceComparisonResponse])
async def compare_prices(
    product_ids: List[int],
    db: Session = Depends(get_db)
):
    """Compare prices for multiple products across stores."""
    service = PriceComparisonService(db)
    return service.compare_prices(product_ids)

@router.get("/alerts/price", response_model=List[PriceAlertResponse])
async def get_price_alerts(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get price alerts for products in user's shopping list."""
    service = PriceComparisonService(db)
    return service.get_price_alerts(user_id) 