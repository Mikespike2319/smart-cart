from typing import List, Dict, Optional
from datetime import datetime, timedelta
import logging
from sqlalchemy.orm import Session
from sqlalchemy import func
import numpy as np
from sklearn.linear_model import LinearRegression
from ..models import Product, Price, Store
from ..ml.price_predictor import PricePredictor

logger = logging.getLogger(__name__)

class PriceComparisonService:
    def __init__(self, db: Session):
        self.db = db
        self.price_predictor = PricePredictor()

    def get_product_prices(self, product_id: int) -> List[Dict]:
        """Get current prices for a product across all stores."""
        prices = (
            self.db.query(Price, Store)
            .join(Product)
            .join(Store)
            .filter(Price.product_id == product_id)
            .order_by(Price.timestamp.desc())
            .all()
        )

        # Group prices by store and get the latest price for each store
        store_prices = {}
        for price, store in prices:
            if store.id not in store_prices:
                store_prices[store.id] = {
                    "store_name": store.name,
                    "price": price.price,
                    "currency": price.currency,
                    "is_sale": price.is_sale,
                    "sale_end_date": price.sale_end_date,
                    "timestamp": price.timestamp
                }

        return list(store_prices.values())

    def get_price_history(self, product_id: int, days: int = 30) -> List[Dict]:
        """Get price history for a product."""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        prices = (
            self.db.query(Price, Store)
            .join(Product)
            .join(Store)
            .filter(Price.product_id == product_id)
            .filter(Price.timestamp >= start_date)
            .order_by(Price.timestamp.asc())
            .all()
        )

        return [
            {
                "store_name": store.name,
                "price": price.price,
                "timestamp": price.timestamp,
                "is_sale": price.is_sale
            }
            for price, store in prices
        ]

    def predict_future_prices(self, product_id: int, days_ahead: int = 7) -> Dict:
        """Predict future prices for a product."""
        # Get historical prices
        price_history = self.get_price_history(product_id)
        
        if not price_history:
            return {"error": "No price history available for prediction"}

        # Prepare data for prediction
        X = np.array([(p["timestamp"] - datetime.utcnow()).days for p in price_history]).reshape(-1, 1)
        y = np.array([p["price"] for p in price_history])

        # Train model
        model = LinearRegression()
        model.fit(X, y)

        # Predict future prices
        future_days = np.array(range(1, days_ahead + 1)).reshape(-1, 1)
        predictions = model.predict(future_days)

        return {
            "predictions": [
                {
                    "days_ahead": int(days),
                    "predicted_price": float(price),
                    "confidence": 0.8  # This would be calculated based on model metrics
                }
                for days, price in zip(future_days.flatten(), predictions)
            ]
        }

    def find_best_deals(self, category: Optional[str] = None, limit: int = 10) -> List[Dict]:
        """Find the best deals across all products."""
        query = (
            self.db.query(
                Product,
                Store,
                Price,
                func.avg(Price.price).over(partition_by=Product.id).label('avg_price')
            )
            .join(Price)
            .join(Store)
            .filter(Price.timestamp >= datetime.utcnow() - timedelta(days=7))
        )

        if category:
            query = query.filter(Product.category == category)

        results = query.all()

        deals = []
        for product, store, price, avg_price in results:
            discount = ((avg_price - price.price) / avg_price) * 100
            deals.append({
                "product_id": product.id,
                "product_name": product.name,
                "store_name": store.name,
                "current_price": price.price,
                "average_price": avg_price,
                "discount_percentage": discount,
                "is_sale": price.is_sale,
                "sale_end_date": price.sale_end_date
            })

        # Sort by discount percentage and return top deals
        return sorted(deals, key=lambda x: x["discount_percentage"], reverse=True)[:limit]

    def compare_prices(self, product_ids: List[int]) -> List[Dict]:
        """Compare prices for multiple products across stores."""
        results = []
        
        for product_id in product_ids:
            product = self.db.query(Product).filter(Product.id == product_id).first()
            if not product:
                continue

            prices = self.get_product_prices(product_id)
            if not prices:
                continue

            # Find the lowest price
            lowest_price = min(prices, key=lambda x: x["price"])
            
            results.append({
                "product_id": product.id,
                "product_name": product.name,
                "prices": prices,
                "lowest_price": lowest_price,
                "price_difference": {
                    store["store_name"]: store["price"] - lowest_price["price"]
                    for store in prices
                }
            })

        return results

    def get_price_alerts(self, user_id: int) -> List[Dict]:
        """Get price alerts for products in user's shopping list."""
        # Get user's shopping list items
        shopping_list_items = (
            self.db.query(ShoppingListItem)
            .filter(ShoppingListItem.user_id == user_id)
            .all()
        )

        alerts = []
        for item in shopping_list_items:
            product = item.product
            prices = self.get_product_prices(product.id)
            
            if not prices:
                continue

            # Check if any store has a price below user's target price
            # (This would come from user preferences)
            target_price = 0  # This would be fetched from user preferences
            
            for price in prices:
                if price["price"] <= target_price:
                    alerts.append({
                        "product_id": product.id,
                        "product_name": product.name,
                        "store_name": price["store_name"],
                        "current_price": price["price"],
                        "target_price": target_price,
                        "savings": target_price - price["price"]
                    })

        return alerts 