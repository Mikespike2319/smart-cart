from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime

class PriceResponse(BaseModel):
    store_name: str
    price: float
    currency: str = "USD"
    is_sale: bool = False
    sale_end_date: Optional[datetime] = None
    timestamp: datetime

class PriceHistoryResponse(BaseModel):
    store_name: str
    price: float
    timestamp: datetime
    is_sale: bool = False

class PricePredictionResponse(BaseModel):
    days_ahead: int
    predicted_price: float
    confidence: float = Field(ge=0.0, le=1.0)

class DealResponse(BaseModel):
    product_id: int
    product_name: str
    store_name: str
    current_price: float
    average_price: float
    discount_percentage: float
    is_sale: bool = False
    sale_end_date: Optional[datetime] = None

class PriceComparisonResponse(BaseModel):
    product_id: int
    product_name: str
    prices: List[PriceResponse]
    lowest_price: PriceResponse
    price_difference: Dict[str, float]

class PriceAlertResponse(BaseModel):
    product_id: int
    product_name: str
    store_name: str
    current_price: float
    target_price: float
    savings: float 