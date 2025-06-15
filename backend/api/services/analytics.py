from typing import List, Dict, Optional
from datetime import datetime, timedelta
from sqlalchemy import func, and_
from sqlalchemy.orm import Session

from api.models import User, Product, Price, ShoppingList, ShoppingListItem, PriceAlert

class AnalyticsService:
    def __init__(self, db: Session):
        self.db = db

    def get_user_savings(self, user_id: int, days: int = 30) -> Dict:
        """Calculate user's savings over time."""
        # Get user's shopping lists
        shopping_lists = self.db.query(ShoppingList).filter(
            ShoppingList.user_id == user_id
        ).all()

        if not shopping_lists:
            return {
                'total_savings': 0,
                'savings_by_day': [],
                'savings_by_category': {},
                'best_deals': []
            }

        # Calculate savings for each shopping list
        total_savings = 0
        savings_by_day = []
        savings_by_category = {}
        best_deals = []

        for shopping_list in shopping_lists:
            items = self.db.query(ShoppingListItem).filter(
                ShoppingListItem.shopping_list_id == shopping_list.id
            ).all()

            for item in items:
                # Get product prices
                prices = self.db.query(Price).filter(
                    Price.product_id == item.product_id
                ).order_by(Price.timestamp.desc()).all()

                if not prices:
                    continue

                # Calculate savings
                lowest_price = min(p.price for p in prices)
                highest_price = max(p.price for p in prices)
                savings = (highest_price - lowest_price) * item.quantity
                total_savings += savings

                # Add to savings by day
                for price in prices:
                    savings_by_day.append({
                        'date': price.timestamp.date().isoformat(),
                        'savings': savings
                    })

                # Add to savings by category
                product = self.db.query(Product).get(item.product_id)
                if product and product.category:
                    if product.category not in savings_by_category:
                        savings_by_category[product.category] = 0
                    savings_by_category[product.category] += savings

                # Add to best deals
                best_deals.append({
                    'product_name': product.name if product else 'Unknown',
                    'savings': savings,
                    'quantity': item.quantity
                })

        # Sort and limit best deals
        best_deals.sort(key=lambda x: x['savings'], reverse=True)
        best_deals = best_deals[:5]

        return {
            'total_savings': total_savings,
            'savings_by_day': savings_by_day,
            'savings_by_category': savings_by_category,
            'best_deals': best_deals
        }

    def get_price_trends(self, product_id: int, days: int = 30) -> Dict:
        """Analyze price trends for a product."""
        # Get price history
        prices = self.db.query(Price).filter(
            Price.product_id == product_id,
            Price.timestamp >= datetime.utcnow() - timedelta(days=days)
        ).order_by(Price.timestamp).all()

        if not prices:
            return {
                'price_history': [],
                'price_stats': {},
                'sale_frequency': 0,
                'best_time_to_buy': None
            }

        # Calculate price statistics
        price_values = [p.price for p in prices]
        avg_price = sum(price_values) / len(price_values)
        min_price = min(price_values)
        max_price = max(price_values)

        # Calculate sale frequency
        sale_count = sum(1 for p in prices if p.is_sale)
        sale_frequency = sale_count / len(prices)

        # Find best time to buy
        best_time = None
        best_price = float('inf')
        for price in prices:
            if price.price < best_price:
                best_price = price.price
                best_time = price.timestamp

        return {
            'price_history': [
                {
                    'date': p.timestamp.date().isoformat(),
                    'price': p.price,
                    'is_sale': p.is_sale
                }
                for p in prices
            ],
            'price_stats': {
                'average_price': avg_price,
                'minimum_price': min_price,
                'maximum_price': max_price,
                'price_range': max_price - min_price
            },
            'sale_frequency': sale_frequency,
            'best_time_to_buy': best_time.date().isoformat() if best_time else None
        }

    def get_user_insights(self, user_id: int) -> Dict:
        """Generate insights for a user's shopping behavior."""
        # Get user's shopping lists
        shopping_lists = self.db.query(ShoppingList).filter(
            ShoppingList.user_id == user_id
        ).all()

        if not shopping_lists:
            return {
                'shopping_frequency': 0,
                'average_list_size': 0,
                'favorite_categories': [],
                'price_alerts': []
            }

        # Calculate shopping frequency
        list_dates = [sl.created_at for sl in shopping_lists]
        list_dates.sort()
        if len(list_dates) > 1:
            time_diff = (list_dates[-1] - list_dates[0]).days
            shopping_frequency = len(list_dates) / (time_diff / 7)  # Lists per week
        else:
            shopping_frequency = 1

        # Calculate average list size
        total_items = 0
        for sl in shopping_lists:
            items = self.db.query(ShoppingListItem).filter(
                ShoppingListItem.shopping_list_id == sl.id
            ).count()
            total_items += items
        average_list_size = total_items / len(shopping_lists)

        # Get favorite categories
        category_counts = {}
        for sl in shopping_lists:
            items = self.db.query(ShoppingListItem).filter(
                ShoppingListItem.shopping_list_id == sl.id
            ).all()
            for item in items:
                product = self.db.query(Product).get(item.product_id)
                if product and product.category:
                    if product.category not in category_counts:
                        category_counts[product.category] = 0
                    category_counts[product.category] += 1

        favorite_categories = sorted(
            category_counts.items(),
            key=lambda x: x[1],
            reverse=True
        )[:5]

        # Get active price alerts
        alerts = self.db.query(PriceAlert).filter(
            PriceAlert.user_id == user_id,
            PriceAlert.is_active == True
        ).all()

        price_alerts = []
        for alert in alerts:
            product = self.db.query(Product).get(alert.product_id)
            if product:
                price_alerts.append({
                    'product_name': product.name,
                    'target_price': alert.target_price,
                    'created_at': alert.created_at.date().isoformat()
                })

        return {
            'shopping_frequency': shopping_frequency,
            'average_list_size': average_list_size,
            'favorite_categories': [
                {'category': cat, 'count': count}
                for cat, count in favorite_categories
            ],
            'price_alerts': price_alerts
        }

    def get_store_comparison(self, product_id: int) -> Dict:
        """Compare prices across different stores."""
        # Get all prices for the product
        prices = self.db.query(Price).filter(
            Price.product_id == product_id
        ).order_by(Price.timestamp.desc()).all()

        if not prices:
            return {
                'store_prices': [],
                'price_differences': {},
                'best_store': None
            }

        # Group prices by store
        store_prices = {}
        for price in prices:
            store = self.db.query(Store).get(price.store_id)
            if not store:
                continue

            if store.name not in store_prices:
                store_prices[store.name] = []
            store_prices[store.name].append(price.price)

        # Calculate average prices by store
        store_avg_prices = {
            store: sum(prices) / len(prices)
            for store, prices in store_prices.items()
        }

        # Find best store
        best_store = min(
            store_avg_prices.items(),
            key=lambda x: x[1]
        )[0]

        # Calculate price differences
        price_differences = {}
        for store1, price1 in store_avg_prices.items():
            for store2, price2 in store_avg_prices.items():
                if store1 != store2:
                    key = f"{store1}_vs_{store2}"
                    price_differences[key] = price1 - price2

        return {
            'store_prices': [
                {
                    'store': store,
                    'average_price': price,
                    'price_range': {
                        'min': min(store_prices[store]),
                        'max': max(store_prices[store])
                    }
                }
                for store, price in store_avg_prices.items()
            ],
            'price_differences': price_differences,
            'best_store': best_store
        } 